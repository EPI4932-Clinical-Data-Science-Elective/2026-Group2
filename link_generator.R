# =========================================================
# GitHub Pages Link Generator (Recursive HTML Discovery)
#   - Recursively finds *.html under the script directory
#   - Copies each HTML + matching *_files dependency folder into /docs
#   - Detects GitHub repo from git remote (origin)
#   - Prints direct GitHub Pages links
#   - Writes /docs/index.html + /docs/links.md
#
# Requirements:
#   - Executed inside a git repo with remote.origin.url set
#   - GitHub Pages configured: main branch, /docs folder
# =========================================================


# =========================================================
# 0) Packages (minimal)
# =========================================================
required_packages <- c("knitr", "rstudioapi")
for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, dependencies = TRUE)
  }
  suppressPackageStartupMessages(
    library(pkg, character.only = TRUE)
  )
}


# =========================================================
# 1) Path resolution (next to current script)
# =========================================================
get_this_script_dir <- function() {
  p <- knitr::current_input()
  if (!is.null(p) && nzchar(p)) {
    return(normalizePath(dirname(p), winslash = "/", mustWork = FALSE))
  }
  
  if (rstudioapi::isAvailable()) {
    ctx <- rstudioapi::getActiveDocumentContext()
    if (!is.null(ctx$path) && nzchar(ctx$path)) {
      return(normalizePath(dirname(ctx$path), winslash = "/", mustWork = FALSE))
    }
  }
  
  normalizePath(getwd(), winslash = "/", mustWork = FALSE)
}

script_dir <- get_this_script_dir()
docs_dir   <- file.path(script_dir, "docs")

if (!dir.exists(docs_dir)) dir.create(docs_dir, recursive = TRUE)


# =========================================================
# 2) GitHub repo detection (owner/repo from origin)
# =========================================================
get_github_owner_repo <- function() {
  remote <- tryCatch(
    system("git config --get remote.origin.url", intern = TRUE),
    error = function(e) character(0)
  )
  
  remote <- trimws(remote)
  if (length(remote) == 0 || !nzchar(remote)) {
    stop("Git remote origin not found. Ensure git repo exists and remote.origin.url is set.")
  }
  
  remote <- sub("\\.git$", "", remote)
  
  owner_repo <- NA_character_
  
  if (grepl("^git@github\\.com:", remote)) {
    owner_repo <- sub("^git@github\\.com:", "", remote)
  } else if (grepl("^https?://github\\.com/", remote)) {
    owner_repo <- sub("^https?://github\\.com/", "", remote)
  }
  
  if (is.na(owner_repo) || !grepl(".+/.+", owner_repo)) {
    stop("Remote origin URL not recognised as GitHub. Found: ", remote)
  }
  
  parts <- strsplit(owner_repo, "/", fixed = TRUE)[[1]]
  list(owner = parts[[1]], repo = parts[[2]])
}

gh <- get_github_owner_repo()
pages_base_url <- paste0("https://", gh$owner, ".github.io/", gh$repo, "/")


# =========================================================
# 3) Recursively locate existing HTML files
#   - Skips anything already under /docs
#   - Skips index.html to avoid duplication loops
# =========================================================
html_files <- list.files(
  path = script_dir,
  pattern = "\\.html$",
  full.names = TRUE,
  recursive = TRUE
)

html_files <- html_files[!grepl("/docs/", html_files)]
html_files <- html_files[basename(html_files) != "index.html"]

if (length(html_files) == 0) {
  stop("No HTML files found under script directory (recursive): ", script_dir)
}


# =========================================================
# 4) Copy HTML + matching *_files folders into /docs
#   - Flattens output: all HTML land directly in /docs
#   - Name collisions handled by prefixing relative folder path
# =========================================================
copy_dir_recursive <- function(from_dir, to_dir) {
  if (dir.exists(to_dir)) unlink(to_dir, recursive = TRUE)
  dir.create(to_dir, recursive = TRUE)
  
  paths <- list.files(from_dir, full.names = TRUE, recursive = FALSE, include.dirs = TRUE)
  if (length(paths) == 0) return(invisible(NULL))
  
  file.copy(from = paths, to = to_dir, recursive = TRUE, overwrite = TRUE)
  invisible(NULL)
}

safe_slug <- function(x) {
  x <- gsub("^\\./", "", x)
  x <- gsub("[/\\\\]", "__", x)
  x <- gsub("[^A-Za-z0-9_.-]", "_", x)
  x
}

copied_html_names <- character(0)

for (html_path in html_files) {
  
  rel_path <- sub(paste0("^", gsub("([\\^\\$\\.|\\(\\)\\[\\]\\*\\+\\?\\\\])", "\\\\\\1", script_dir), "/?"), "", html_path)
  rel_dir  <- dirname(rel_path)
  
  original_file_name <- basename(html_path)
  original_base_name <- tools::file_path_sans_ext(original_file_name)
  
  # Output name to avoid collisions across subfolders
  prefix <- if (rel_dir == "." || rel_dir == "") "" else paste0(safe_slug(rel_dir), "__")
  out_html_name <- paste0(prefix, original_file_name)
  out_base_name <- tools::file_path_sans_ext(out_html_name)
  
  # Copy HTML
  file.copy(html_path, file.path(docs_dir, out_html_name), overwrite = TRUE)
  copied_html_names <- c(copied_html_names, out_html_name)
  
  # Dependency folder next to original html:
  # <same_folder>/<original_base_name>_files
  src_dep <- file.path(dirname(html_path), paste0(original_base_name, "_files"))
  
  if (dir.exists(src_dep)) {
    dest_dep <- file.path(docs_dir, paste0(out_base_name, "_files"))
    copy_dir_recursive(src_dep, dest_dep)
  }
}


# =========================================================
# 5) Generate GitHub Pages links
# =========================================================
links <- paste0(pages_base_url, copied_html_names)


# =========================================================
# 6) Write /docs/index.html (launcher)
# =========================================================
index_lines <- c(
  "<!DOCTYPE html>",
  "<html>",
  "<head>",
  "<meta charset='UTF-8'>",
  "<meta name='viewport' content='width=device-width, initial-scale=1'>",
  "<title>Interactive Maps</title>",
  "<style>",
  "body { font-family: Arial, sans-serif; padding: 40px; max-width: 900px; }",
  "h1 { margin-bottom: 10px; }",
  "p { color: #444; }",
  "a { display: block; margin: 10px 0; font-size: 18px; }",
  "code { background: #f5f5f5; padding: 2px 6px; border-radius: 6px; }",
  "</style>",
  "</head>",
  "<body>",
  "<h1>Interactive Maps</h1>",
  "<p>GitHub Pages base URL: <code>",
  pages_base_url,
  "</code></p>",
  "<p>Index: <a href='index.html'>index.html</a></p>",
  "<hr/>"
)

for (nm in copied_html_names) {
  index_lines <- c(index_lines, paste0("<a href='", nm, "'>", nm, "</a>"))
}

index_lines <- c(index_lines, "</body>", "</html>")
writeLines(index_lines, file.path(docs_dir, "index.html"))


# =========================================================
# 7) Write /docs/links.md (copy-paste)
# =========================================================
md_lines <- c(
  "# Direct links (GitHub Pages)",
  "",
  paste0("- Base: ", pages_base_url),
  paste0("- Index: ", pages_base_url, "index.html"),
  "",
  "## Pages",
  ""
)

for (i in seq_along(copied_html_names)) {
  md_lines <- c(md_lines, paste0("- ", copied_html_names[[i]], ": ", links[[i]]))
}

writeLines(md_lines, file.path(docs_dir, "links.md"))


# =========================================================
# 8) Console output
# =========================================================
cat("=================================================\n")
cat("GitHub Pages links (direct open)\n")
cat("=================================================\n\n")
cat("Base:\n", pages_base_url, "\n\n", sep = "")
cat("Index:\n", paste0(pages_base_url, "index.html"), "\n\n", sep = "")
cat("Pages:\n", sep = "")

for (i in seq_along(copied_html_names)) {
  cat(" - ", copied_html_names[[i]], "  =>  ", links[[i]], "\n", sep = "")
}

cat("\nFiles written:\n")
cat(" - ", file.path(docs_dir, "index.html"), "\n", sep = "")
cat(" - ", file.path(docs_dir, "links.md"), "\n", sep = "")
cat("\nCommit /docs and enable GitHub Pages (main branch → /docs).\n")