$command=$args[0]

Switch ($command) {
  "path" {
    & ".\runtime\Path{space}of{space}Building.exe"
    Break
  }
  "test" {
    busted --lua=luajit
    Break
  }
  "rebase" {
    $result = git remote show upstream
    $fetch_url = $result[1].Trim().Substring("Fetch URL: ".length)

    if ($fetch_url -eq "https://github.com/PathOfBuildingCommunity/PathOfBuilding.git") {
      git fetch upstream
      $current_branch = git branch --show-current
      
      if ($current_branch -eq "dev") {
        git rebase upstream/dev
        git push -f origin $current_branch
      } else {
        $ans = Read-Host "Not in dev branch. Do you wish to continue? Yes[Y]/No[N]`n"
        $ans = $ans.ToLower()
        
        Do {
          Switch ($ans) {
            "y" {
              git rebase upstream/dev
              git push -f origin $current_branch
              Return
            }
            "n" {
              Write-Output "Aborting rebase"
              Return
            }
            Default {
              $ans = Read-Host "$ans is not a valid option. Not in dev branch. Do you wish to continue? Yes[Y]/No[N]`n"
              $ans = $ans.ToLower()
            }
          }
        } While ($True)
      }
    } else {
      Write-Output 'Upstream remote not set to \"https://github.com/PathOfBuildingCommunity/PathOfBuilding.git\"'
    }
    Break
  }
}