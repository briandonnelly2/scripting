function Get-PackageFolderDetails {
    <#
    .SYNOPSIS
    Gets a package version path from the filename in a provided path.

    .PARAMETER Path
    The path to identify version folders for. Can either be just a filename or a full path.
    URLs are currently not supported.
    #>

    [CmdletBinding()]
    param(
        [string] $Path
    )

    # Using regular expressions to split the version from the name.
    # A version is at least group of numbers and periods of any length, e.g. '1.2.3.0' or simply '1'

    $regex = [regex]::Match($Path, '^(?<folder>(?:.*\\)?)(?<name>.*?)\.?(?<version>(?:[0-9]+\.?)+)?\.\w+$')
    return @{
        Folder = $regex.Groups['folder'].Value
        Name = $regex.Groups['name'].Value;
        Version = $regex.Groups['version'].Value
    }
}