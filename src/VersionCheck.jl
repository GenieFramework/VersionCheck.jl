module VersionCheck

using Pkg, Logging, Dates, Random
using JSON3, UrlDownload
using Scratch

const version_info_bounds = r"start-versions-->(.*)<!--end-versions"s
const usersettings_filename = "usersettings.json"

# changelog_url = "https://genieframework.com/CHANGELOG.html"
usersettings = Dict()

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
function versioninfo(pkgname::String; url::String) :: Union{JSON3.Object,Nothing}
  try
    changelog(url)[:packages][pkgname][:releases][1]
  catch ex
    nothing
  end
end


"""
Checks if a new version is available for `pkgname`
"""
function newversion(pkgname::String; show_message = true, url::String) :: Bool
  usersettings["enabled"] || return

  vinfo = versioninfo(pkgname; url = url)
  pinfo = dependencyinfo(pkgname)

  if pinfo.version < VersionNumber(vinfo[:version])
    if show_message && ((time() - usersettings["last_check"]) > usersettings["warn_frequency"] * 60 * 60)
      @info "A new version ($(vinfo.version)) of $pkgname is available. You use version $(pinfo.version)."
    end

    save_usersettings("last_check" => time())

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
function changelog(url::String) :: JSON3.Object
  url = (occursin("?", url) ? url * "&" : url * "?") * "id=$(usersettings["id"])"

  urldownload(url, parser = textparser)
end


function default_usersettings()
  Dict(
      "enabled" => true,
      "warn_frequency" => 24, # hours
      "last_check" => 0.0, # time()
      "id" => (randstring(24) |> uppercase)
    )
end


function valid_usersettings(d::T) where {T<:AbstractDict}
  issubset(collect(keys(default_usersettings())), string.(collect(keys(d))))
end


"""
Retrieves user settings from scratch
"""
function get_usersettings()
  settings_file = joinpath(@get_scratch!("downloaded_files"), usersettings_filename)
  defaults = default_usersettings()

  if ! isfile(settings_file)
    defaults |> save_usersettings
  else
    try
      us = read(settings_file, String) |> JSON3.read
      valid_usersettings(us) || error("Invalid usersettings file")

      us
    catch ex
      # @error ex

      defaults |> save_usersettings
    end
  end
end


"""
Persists user settings to scratch
"""
function save_usersettings(us::T) where {T<:AbstractDict}
  settings_file = joinpath(@get_scratch!("downloaded_files"), usersettings_filename)

  open(settings_file, "w") do io
    JSON3.write(io, us)
  end

  global usersettings = us
end
function save_usersettings(p::Pair)
  usersettings[p[1]] = p[2]
  save_usersettings(usersettings)
end


function __init__()
  global usersettings = get_usersettings()
end


module Changelog

function generate()
  @warn "TODO: implement"
end

function exportmd()
  @warn "TODO: implement"
end

end


end
