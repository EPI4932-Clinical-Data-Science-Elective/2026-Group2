# =========================================================
# HDI (2019) — Interactive Maps + Diagnostics Exports
#   - Flat world + Rotatable globe
#   - Uses human_development_index from Covid_cleaned.csv
#   - 2-trace strategy: non-missing (coloured) + missing (grey)
#
# Path principles (no hard-coded script folder name):
#   - Input read from PROJECT ROOT via here::here(...)
#   - Output written next to this script via knitr::current_input()
# =========================================================


# =========================================================
# 0) Packages (install if missing; load quietly)
# =========================================================
required_packages <- c(
  "readr", "dplyr", "here", "countrycode",
  "plotly", "rnaturalearth", "sf",
  "htmlwidgets", "knitr", "rstudioapi"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, dependencies = TRUE)
  }
  suppressPackageStartupMessages(
    library(pkg, character.only = TRUE)
  )
}


# =========================================================
# 1) Output path helpers (no hard-coding)
#   - out_dir = folder containing this script
#   - out_path("x.csv") returns full path inside out_dir
# =========================================================
get_this_script_dir <- function() {
  # --- 1) Knitting context (Rmd / Quarto)
  p <- knitr::current_input()
  if (!is.null(p) && nzchar(p)) {
    return(normalizePath(dirname(p), winslash = "/", mustWork = FALSE))
  }
  
  # --- 2) Interactive RStudio context
  if (rstudioapi::isAvailable()) {
    ctx <- rstudioapi::getActiveDocumentContext()
    if (!is.null(ctx$path) && nzchar(ctx$path)) {
      return(normalizePath(dirname(ctx$path), winslash = "/", mustWork = FALSE))
    }
  }
  
  # --- 3) Fallback
  normalizePath(getwd(), winslash = "/", mustWork = FALSE)
}

out_dir <- get_this_script_dir()

out_path <- function(...) {
  file.path(out_dir, ...)
}

if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)


# =========================================================
# 2) Small helpers (robustness)
# =========================================================
first_non_na <- function(x) {
  x2 <- x[!is.na(x)]
  if (length(x2) == 0) NA else x2[[1]]
}


# =========================================================
# 3) Read dataset (PROJECT ROOT)
# =========================================================
csv_path <- here::here("open_covid_data", "Covid_cleaned.csv")
if (!file.exists(csv_path)) stop("File not found: ", csv_path)

df <- readr::read_csv(csv_path, show_col_types = FALSE)

needed_cols <- c("location", "continent", "human_development_index")
missing_cols <- setdiff(needed_cols, names(df))
if (length(missing_cols) > 0) {
  stop("Missing required columns in CSV: ", paste(missing_cols, collapse = ", "))
}


# =========================================================
# 4) Name -> ISO3 conversion (targeted fixes)
# =========================================================
name_fixes <- c(
  "Timor" = "Timor-Leste",
  "East Timor" = "Timor-Leste",
  "Congo" = "Republic of the Congo",
  "Congo (Brazzaville)" = "Republic of the Congo",
  "Congo (Kinshasa)" = "Democratic Republic of the Congo",
  "DR Congo" = "Democratic Republic of the Congo",
  "Czechia" = "Czech Republic",
  "Cape Verde" = "Cabo Verde",
  "Swaziland" = "Eswatini",
  "Ivory Coast" = "Côte d’Ivoire",
  "Cote d'Ivoire" = "Côte d’Ivoire",
  "Cote dIvoire" = "Côte d’Ivoire",
  "Myanmar (Burma)" = "Myanmar",
  "North Macedonia" = "Macedonia"
)

df <- df %>%
  dplyr::mutate(
    location_clean = dplyr::if_else(
      location %in% names(name_fixes),
      unname(name_fixes[location]),
      location
    ),
    iso_code = countrycode::countrycode(
      sourcevar   = location_clean,
      origin      = "country.name",
      destination = "iso3c",
      warn        = TRUE
    )
  )

stopifnot("iso_code" %in% names(df))


# =========================================================
# 5) Location-level diagnostics (why rows become unmapped)
# =========================================================
loc_diag <- df %>%
  dplyr::group_by(location, location_clean) %>%
  dplyr::summarise(
    continent_any = any(!is.na(continent)),
    iso_code_any  = first_non_na(iso_code),
    has_iso       = any(!is.na(iso_code)),
    has_hdi       = any(!is.na(human_development_index)),
    .groups = "drop"
  ) %>%
  dplyr::mutate(
    reason = dplyr::case_when(
      !continent_any          ~ "Excluded by filter: continent is NA (aggregate/non-country row)",
      !has_iso                ~ "ISO conversion failed (countrycode could not map name to ISO3)",
      has_iso & !has_hdi      ~ "HDI missing in dataset for this country",
      TRUE                    ~ "OK"
    )
  )

loc_diag_iso <- loc_diag %>%
  dplyr::filter(!is.na(iso_code_any)) %>%
  dplyr::group_by(iso_code_any) %>%
  dplyr::summarise(
    any_hdi_missing        = any(reason == "HDI missing in dataset for this country", na.rm = TRUE),
    any_excluded_by_continent = any(reason == "Excluded by filter: continent is NA (aggregate/non-country row)", na.rm = TRUE),
    any_iso_failed         = any(reason == "ISO conversion failed (countrycode could not map name to ISO3)", na.rm = TRUE),
    .groups = "drop"
  )


# =========================================================
# 6) World polygons index (Natural Earth; ISO fallback)
# =========================================================
world_sf <- rnaturalearth::ne_countries(scale = "medium", returnclass = "sf")

world_index <- world_sf %>%
  sf::st_drop_geometry() %>%
  dplyr::transmute(
    iso_a3 = dplyr::if_else(is.na(iso_a3) | iso_a3 == "-99", adm0_a3, iso_a3),
    name
  ) %>%
  dplyr::distinct() %>%
  dplyr::filter(!is.na(iso_a3), iso_a3 != "-99")


# =========================================================
# 7) Country-level HDI table (continent-filtered)
#   - First non-NA HDI per ISO3
#   - Category thresholds match UNDP bands (common cutpoints)
# =========================================================
hdi_country <- df %>%
  dplyr::filter(!is.na(continent)) %>%
  dplyr::filter(!is.na(iso_code)) %>%
  dplyr::group_by(iso_code) %>%
  dplyr::summarise(
    country  = first_non_na(location_clean),
    hdi_2019 = first_non_na(human_development_index),
    .groups  = "drop"
  ) %>%
  dplyr::filter(!is.na(hdi_2019)) %>%
  dplyr::mutate(
    hdi_category = dplyr::case_when(
      hdi_2019 < 0.550 ~ "Low",
      hdi_2019 < 0.700 ~ "Medium",
      hdi_2019 < 0.800 ~ "High",
      TRUE             ~ "Very high"
    ),
    hdi_category = factor(hdi_category, levels = c("Low", "Medium", "High", "Very high")),
    cat_code = as.integer(hdi_category),
    hover = paste0(
      "<b>", country, "</b>",
      "<br>ISO3: ", iso_code,
      "<br>HDI (2019): ", sprintf("%.3f", hdi_2019),
      "<br>Category: ", as.character(hdi_category)
    )
  )


# =========================================================
# 8) Missing-on-map polygons (diagnostic join)
# =========================================================
missing_on_map <- world_index %>%
  dplyr::left_join(
    hdi_country %>% dplyr::transmute(iso_a3 = iso_code, has_hdi = TRUE),
    by = "iso_a3"
  ) %>%
  dplyr::filter(is.na(has_hdi)) %>%
  dplyr::select(iso_a3, name) %>%
  dplyr::left_join(loc_diag_iso, by = c("iso_a3" = "iso_code_any")) %>%
  dplyr::mutate(
    reason = dplyr::case_when(
      !is.na(any_hdi_missing)        & any_hdi_missing        ~ "HDI missing in dataset for this country",
      !is.na(any_excluded_by_continent) & any_excluded_by_continent ~ "Present in dataset but excluded by continent==NA filter",
      !is.na(any_iso_failed)         & any_iso_failed         ~ "ISO conversion failed in dataset (name mismatch / non-standard label)",
      TRUE ~ "No matching HDI record in dataset"
    ),
    hover = paste0(
      "<b>", name, "</b>",
      "<br>ISO3: ", iso_a3,
      "<br>Status: Missing from HDI map",
      "<br>Reason: ", reason
    )
  ) %>%
  dplyr::select(iso_a3, name, reason, hover)


# =========================================================
# 9) Diagnostics exports (next to this script)
# =========================================================
readr::write_csv(
  hdi_country %>%
    dplyr::select(country, iso_code, hdi_2019, hdi_category) %>%
    dplyr::arrange(country),
  out_path("non_missing_hdi_countries.csv")
)

readr::write_csv(
  missing_on_map %>%
    dplyr::rename(iso_code = iso_a3, country = name) %>%
    dplyr::arrange(country),
  out_path("missing_hdi_or_join_countries.csv")
)

iso_failed_locations <- loc_diag %>%
  dplyr::filter(reason == "ISO conversion failed (countrycode could not map name to ISO3)") %>%
  dplyr::select(location, location_clean, reason) %>%
  dplyr::arrange(location_clean)

readr::write_csv(
  iso_failed_locations,
  out_path("iso_conversion_failed_locations.csv")
)

all_world_polygons_with_status <- world_index %>%
  dplyr::left_join(
    hdi_country %>% dplyr::select(iso_code, country, hdi_2019, hdi_category),
    by = c("iso_a3" = "iso_code")
  ) %>%
  dplyr::left_join(loc_diag_iso, by = c("iso_a3" = "iso_code_any")) %>%
  dplyr::mutate(
    status = dplyr::if_else(!is.na(hdi_2019), "Non-missing (mapped with HDI)", "Missing (grey)"),
    reason = dplyr::case_when(
      status == "Non-missing (mapped with HDI)"                       ~ "OK",
      !is.na(any_hdi_missing) & any_hdi_missing                       ~ "HDI missing in dataset for this country",
      !is.na(any_excluded_by_continent) & any_excluded_by_continent   ~ "Present in dataset but excluded by continent==NA filter",
      !is.na(any_iso_failed) & any_iso_failed                         ~ "ISO conversion failed in dataset (name mismatch / non-standard label)",
      TRUE                                                            ~ "Not present in dataset (or not convertible via dataset location names)"
    )
  ) %>%
  dplyr::transmute(
    iso_code      = iso_a3,
    polygon_name  = name,
    status,
    reason,
    hdi_2019,
    hdi_category
  ) %>%
  dplyr::arrange(status, polygon_name)

readr::write_csv(
  all_world_polygons_with_status,
  out_path("all_world_polygons_with_status.csv")
)

cat("Diagnostics exported to:\n")
cat(" - ", out_path("non_missing_hdi_countries.csv"), "\n", sep = "")
cat(" - ", out_path("missing_hdi_or_join_countries.csv"), "\n", sep = "")
cat(" - ", out_path("iso_conversion_failed_locations.csv"), "\n", sep = "")
cat(" - ", out_path("all_world_polygons_with_status.csv"), "\n\n", sep = "")

cat("ISO conversion failures (rows): ", sum(is.na(df$iso_code)), "\n", sep = "")
cat("Unique locations failing ISO conversion: ", nrow(iso_failed_locations), "\n\n", sep = "")


# =========================================================
# 10) Map data preparation (polygon join; 2-trace split)
# =========================================================
map_data <- world_index %>%
  dplyr::left_join(
    hdi_country %>% dplyr::select(iso_code, cat_code, hover),
    by = c("iso_a3" = "iso_code")
  ) %>%
  dplyr::mutate(
    hover = dplyr::if_else(
      is.na(cat_code),
      paste0(
        "<b>", name, "</b>",
        "<br>ISO3: ", iso_a3,
        "<br>Status: Missing HDI (2019)"
      ),
      hover
    )
  )

map_non_missing <- map_data %>% dplyr::filter(!is.na(cat_code))
map_missing     <- map_data %>% dplyr::filter(is.na(cat_code))


# =========================================================
# 11) Categorical palette (4 bins; discrete blocks)
# =========================================================
pal4 <- c(
  "#08306B",  # Low
  "#2171B5",  # Medium
  "#41B6C4",  # High
  "#C7E9F1"   # Very high
)

colorscale_hdi <- list(
  list(0.00, pal4[1]), list(0.2499, pal4[1]),
  list(0.25, pal4[2]), list(0.4999, pal4[2]),
  list(0.50, pal4[3]), list(0.7499, pal4[3]),
  list(0.75, pal4[4]), list(1.00, pal4[4])
)


# =========================================================
# 12) Flat world map (2 traces: coloured + grey overlay)
# =========================================================
geo_flat <- list(
  showframe      = FALSE,
  showcoastlines = FALSE,
  projection     = list(type = "natural earth"),
  showocean      = TRUE,
  oceancolor     = "#FAFAFA",
  showland       = TRUE,
  landcolor      = "#FFFFFF",
  showcountries  = TRUE,
  countrycolor   = "#FFFFFF"
)

map_flat <- plotly::plot_ly() %>%
  plotly::add_trace(
    data         = map_non_missing,
    type         = "choropleth",
    locations    = ~iso_a3,
    locationmode = "ISO-3",
    z            = ~cat_code,
    text         = ~hover,
    hoverinfo    = "text",
    colorscale   = colorscale_hdi,
    autocolorscale = FALSE,
    zauto        = FALSE,
    zmin         = 1,
    zmax         = 4,
    showscale    = TRUE,
    colorbar     = list(
      title = "HDI category",
      tickmode = "array",
      tickvals = c(1, 2, 3, 4),
      ticktext = c("Low", "Medium", "High", "Very high")
    ),
    marker       = list(line = list(color = "#FFFFFF", width = 0.3))
  ) %>%
  plotly::add_trace(
    data         = map_missing,
    type         = "choropleth",
    locations    = ~iso_a3,
    locationmode = "ISO-3",
    z            = I(1),
    text         = ~hover,
    hoverinfo    = "text",
    colorscale   = list(list(0, "#BDBDBD"), list(1, "#BDBDBD")),
    showscale    = FALSE,
    marker       = list(line = list(color = "#FFFFFF", width = 0.3))
  ) %>%
  plotly::layout(
    title  = "HDI categories (2019) Flat World",
    geo    = geo_flat,
    margin = list(l = 0, r = 0, t = 70, b = 0)
  )

map_flat

map_flat$sizingPolicy <- htmlwidgets::sizingPolicy(
  browser.fill = TRUE,
  viewer.fill  = TRUE,
  padding      = 0
)

flat_html   <- out_path("HDI2019_FlatWorld.html")
flat_libdir <- out_path("HDI2019_FlatWorld_files")

htmlwidgets::saveWidget(
  widget        = map_flat,
  file          = flat_html,
  selfcontained = FALSE,
  libdir        = flat_libdir
)

browseURL(flat_html)


# =========================================================
# 13) Rotatable globe (orthographic; same 2-trace logic)
# =========================================================
geo_globe <- list(
  projection = list(type = "orthographic", rotation = list(lon = 10, lat = 20)),
  showframe      = FALSE,
  showocean      = TRUE,
  oceancolor     = "#FAFAFA",
  showland       = TRUE,
  landcolor      = "#FFFFFF",
  showcoastlines = TRUE,
  coastlinecolor = "rgba(0,0,0,0.15)",
  showcountries  = TRUE,
  countrycolor   = "#FFFFFF",
  showlakes      = TRUE,
  lakecolor      = "#F2F2F2"
)

map_globe <- plotly::plot_ly() %>%
  plotly::add_trace(
    data         = map_non_missing,
    type         = "choropleth",
    locations    = ~iso_a3,
    locationmode = "ISO-3",
    z            = ~cat_code,
    text         = ~hover,
    hoverinfo    = "text",
    colorscale   = colorscale_hdi,
    autocolorscale = FALSE,
    zauto        = FALSE,
    zmin         = 1,
    zmax         = 4,
    showscale    = TRUE,
    colorbar     = list(
      title = "HDI category",
      tickmode = "array",
      tickvals = c(1, 2, 3, 4),
      ticktext = c("Low", "Medium", "High", "Very high")
    ),
    marker       = list(line = list(color = "#FFFFFF", width = 0.4))
  ) %>%
  plotly::add_trace(
    data         = map_missing,
    type         = "choropleth",
    locations    = ~iso_a3,
    locationmode = "ISO-3",
    z            = I(1),
    text         = ~hover,
    hoverinfo    = "text",
    colorscale   = list(list(0, "#BDBDBD"), list(1, "#BDBDBD")),
    showscale    = FALSE,
    marker       = list(line = list(color = "#FFFFFF", width = 0.4))
  ) %>%
  plotly::layout(
    title  = "HDI categories (2019): Rotatable globe",
    geo    = geo_globe,
    margin = list(l = 0, r = 0, t = 70, b = 0)
  ) %>%
  plotly::config(displayModeBar = TRUE, scrollZoom = TRUE)

map_globe

map_globe$sizingPolicy <- htmlwidgets::sizingPolicy(
  browser.fill = TRUE,
  viewer.fill  = TRUE,
  padding      = 0
)

globe_html   <- out_path("HDI2019_RotatableGlobe.html")
globe_libdir <- out_path("HDI2019_RotatableGlobe_files")

htmlwidgets::saveWidget(
  widget        = map_globe,
  file          = globe_html,
  selfcontained = FALSE,
  libdir        = globe_libdir
)

browseURL(globe_html)