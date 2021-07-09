 <#
.SYNOPSIS
This script will saturate a specified number of CPU cores to 100% utilization.
.DESCRIPTION
This script will saturate a specified number of CPU cores to 100% utilization.
.PARAMETER <>
.INPUTS
None.
.EXAMPLE
.\Invoke-CPUStress.ps1
.NOTES
TAG:PUBLIC
#>

try {
    $NumThreads = Get-WmiObject win32_processor | Select-Object -ExpandProperty NumberOfLogicalProcessors

    $StartDate = Get-Date
    Write-Output "============= CPU Stress Test Started: $StartDate ============="
    Write-Warning "This script will potentially saturate CPU utilization!"
    
    
    Write-Warning "To cancel execution of all jobs, close the PowerShell Host Window."
    Write-Output "Hyper Core Count: $NumThreads"

    foreach ($loopnumber in 1..$NumThreads){
        Start-Job -ScriptBlock{
        $result = 1
            foreach ($number in 1..2147483647){
                $result = $result * $number
            }
        } -Name SSMCpuJob$loopnumber
    }
    
    Start-Sleep -s 60
    
    Stop-Job -Name SSMCpuJob*

    $EndDate = Get-Date
    Write-Output "============= CPU Stress Test Complete: $EndDate ============="
} catch {
    Write-Host "Failed to Run CPU Stress Test"
    Exit 1
}


