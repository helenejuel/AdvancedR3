---
editor_options:
  markdown:
    wrap: 72
    canonical: true
---

# AdvancedR3: Learning about targets and quarto

Check out the project's
[website](https://helenejuel.github.io/AdvancedR3/).

This project is to learn more and maybe end up understanding what I'm
doing.

# Brief description of folder and file contents

The following folders contain:

-   `data/`: wrangled lipidomics dataset
-   `doc/`: quarto markdown
-   `R/`: functions script

# Installing project R package dependencies

If dependencies have been managed by using
`usethis::use_package("packagename")` through the `DESCRIPTION` file,
installing dependencies is as easy as opening the `AdvancedR3.Rproj`
file and running this command in the console:

```         
# install.packages("remotes")
remotes::install_deps()
```

You'll need to have remotes installed for this to work.

# Resource

For more information on this folder and file workflow and setup, check
out the [prodigenr](https://rostools.github.io/prodigenr) online
documentation.

