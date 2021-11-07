module VersionCheck

using Pkg, Logging
using JSON3, UrlDownload

const version_info_bounds = r"start-versions-->(.*)<!--end-versions"s
const changelog_url = "https://genieframework.com/CHANGELOG.html"


"""
Extracts the list of dependencies for the given `pkgname`.
"""
function dependencyinfo(pkgname::String) :: Union{Pkg.Types.PackageInfo,Nothing}
  try
    Pkg.dependencies()[Pkg.project().dependencies[pkgname]]
  catch ex
    nothing
  end
end


"""
Extracts the information about the latest version of `pkgname` using a special CHANGELOG.html file
"""
function versioninfo(pkgname::String; url::String = changelog_url) :: Union{JSON3.Object,Nothing}
  try
    changelog(url)[:packages][pkgname][:releases][1]
  catch ex
    nothing
  end
end


"""
Checks if a new version is available for `pkgname`
"""
function newversion(pkgname::String; show_message = true, url::String = changelog_url) :: Bool
  vinfo = versioninfo(pkgname; url = url)
  pinfo = dependencyinfo(pkgname)

  if pinfo.version < VersionNumber(vinfo[:version])
    if show_message
      @info "
A new version of $pkgname is available.
$pkgname version $(vinfo.version) was released on $(vinfo.date).
You have version $(pinfo.version) installed.
          "
    end

    true
  else
    false
  end
end


"""
Custom CHANGELOG.html parser for UrlDownload
"""
function textparser(content::Vector{UInt8}) :: JSON3.Object
  try
    match(version_info_bounds, String(content))[1] |> JSON3.read
  catch
    error("Invalid CHANGELOG.html document")
  end
end


"""
Downloads the CHANGELOG.html file from `url`
"""
function changelog(url::String = changelog_url) :: JSON3.Object
  urldownload(url, parser = textparser)
end

end
