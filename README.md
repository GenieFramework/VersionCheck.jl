# VersionCheck

Utility package for checking if a new version of a Julia package is available. It uses the current Project.toml file and a special CHANGELOG.html file to determine the latest versions.

## Usage

Create a CHANGELOG.html file similar to the CHANGELOG_sample.html file included in this package. Host the CHANGELOG.html file on a publicly accessible web server.

In your package, add a check like the following:

```julia
module MyPackage

import VersionCheck

function __init__()
  @async VersionCheck.newversion("MyPackage", url = "<URL to CHANGELOG.html>")
end

end
```
