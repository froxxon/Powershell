function Get-RegSummary {
    param ( $file ) 
    $results = get-content $file | convertfrom-csv -Delimiter ';'
    $results | Group-Object DisplayName | 
        Select  @{Name="Display";Expression={$_.Name}},
            @{Name="Match";Expression={ ($_.Group | Where {$_.Status -match "Match"}).Count }},
            @{Name="Diff";Expression={ ($_.Group | Where {$_.Status -match "Different"}).Count }},
            @{Name="Percentage";Expression={ "$((($_.Group | Where {$_.Status -match "Match"}).Count / ($_.Group).Count)*100)%" }} | sort Percentage | ft -AutoSize
}

function Get-URASummary {
    param ( $file ) 
    $results = get-content $file | convertfrom-csv -Delimiter ';'
    $results | Group-Object DisplayName | 
        Select  @{Name="Display";Expression={$_.Name}},
            @{Name="Match";Expression={ ($_.Group | Where {$_.Status -match "Match"}).Count }},
            @{Name="Diff";Expression={ ($_.Group | Where {$_.Status -match "Different"}).Count }},
            @{Name="Percentage";Expression={ "$((($_.Group | Where {$_.Status -match "Match"}).Count / ($_.Group).Count)*100)%" }} | sort Percentage | ft -AutoSize
}

get-regsummary "C:\Users\froxxon\Desktop\SecBaselinePrep\MemberServers-RegSummary.csv"
#get-urasummary "C:\Users\froxxon\Desktop\SecBaselinePrep\MemberServers-URASummary.csv"
