# Auto Git Commit and Push Script
using namespace System.Web

# Debug Configuration
$DEBUG_MODE = $false  # true,false
$LLM_MODEL = "qwen2.5:7b"
$LLM_PROMPT_TEMPLATE = @"
请分析以下Git变更内容，生成一个结构化的commit消息。要求：
- 最前面用一句话总结所有变更内容
- 按照文件分类列出具体修改内容
- [新增]表示新增文件,[修改]表示修改文件,[删除]表示删除文件
- 每个修改项不超过50个字符
- 使用现在进行时
- 直接输出下面的格式：
一句话总结所有变更内容
    - [新增] xxx文件
    - [新增] xxx文件
    - [新增] xxx文件
    - [修改] xxx文件：详细修改内容，...
    - [修改] xxx文件：详细修改内容，...
    - [修改] xxx文件：详细修改内容，...
    - [删除] xxx文件
    - [删除] xxx文件
    - [删除] xxx文件
变更内容：
{0}
"@

# Function to get git diff in a structured format
function Get-GitChanges {
    $stagedFiles = git diff --staged --name-status
    if (-not $stagedFiles) {
        return $null
    }    
    $changes = @{
        "added" = @()
        "modified" = @()
        "deleted" = @()
    }    
    $stagedFiles | ForEach-Object {
        $status, $file = $_ -split "\s+"
        switch ($status) {
            "A" { $changes["added"] += $file }
            "M" { $changes["modified"] += $file }
            "D" { $changes["deleted"] += $file }
        }
    }    
    return $changes
}

# Function to get detailed diff content
function Get-DetailedDiff {
    try {
        $diff = git diff --staged --patch
        if (-not $diff) {
            return "No changes detected"
        }
        # Convert diff output to string and escape special characters
        return [string]::Join("
", $diff)
    }
    catch {
        Write-Host "获取Git差异内容时出错：$($_.Exception.Message)" -ForegroundColor Yellow
        return "Error getting diff content"
    }
}

# Function to generate commit message using Ollama
function Get-LLMCommitMessage {
    param (
        [Parameter(Mandatory=$true)]
        [string]$diffContent
    )    
    $prompt = $LLM_PROMPT_TEMPLATE -f $diffContent    
    $maxRetries = 3
    $retryCount = 0    
    while ($retryCount -lt $maxRetries) {
        try {
            Write-Host "使用的模型：$LLM_MODEL" -ForegroundColor Cyan
            $response = ollama run $LLM_MODEL $prompt 2>$null
            if ($response) {
                # 将数组响应转换为字符串
                $responseStr = $response -join "`n"
                # 保持换行格式，仅清理多余空白
                $cleanResponse = $responseStr.Trim() -replace '(?m)^s+', ''  
                # 移除可能的前缀
                $cleanResponse = $cleanResponse -replace '^commit\s*消息：\s*', ''
                # 确保每个修改项都在新行，使用PowerShell的换行符
                # 提取并格式化总结内容 (匹配以冒号结尾的第一行作为总结, 处理前后空格)
                # Regex to find the first line ending with a colon, capturing content after it
                $summaryMatch = [regex]::Match($cleanResponse, '(?m)^.*?[:：]\s*(.*?)\s*(`r?`n|$)')
                  if ($summaryMatch.Success) {
                      $summaryContent = $summaryMatch.Groups[1].Value.Trim() # Get content after colon

                      # Calculate the starting position of the content *after* the summary line
                      $startIndexAfterSummary = $summaryMatch.Index + $summaryMatch.Length

                      # Get the rest of the message, ensuring we don't go out of bounds
                      $restOfMessage = ""
                      if ($startIndexAfterSummary -lt $cleanResponse.Length) {
                          $restOfMessage = $cleanResponse.Substring($startIndexAfterSummary).TrimStart()
                      }

                      # Reconstruct the message with the standard prefix
                      $cleanResponse = "Summary: $summaryContent`r`n$restOfMessage"
                  }
                  # Ensure list items start on a new line, potentially preceded by whitespace
                  $cleanResponse = $cleanResponse -replace '(?<!\r?\n)\s*-\s*\[', "`r`n- ["
                # 不再进行HTML编码
                # $cleanResponse = [System.Web.HttpUtility]::HtmlEncode($cleanResponse.Trim()) 
                # 不在此处打印，避免重复输出
                return $cleanResponse.Trim() # 清理最终结果的空白
            }
            throw "No response from Ollama"
        }
        catch {
            $retryCount++
            if ($retryCount -lt $maxRetries) {
                Write-Host "LLM请求失败，正在重试 ($retryCount/$maxRetries)..." -ForegroundColor Yellow
                Start-Sleep -Seconds 2
            }
            else {
                Write-Host "无法生成LLM commit消息：$($_.Exception.Message)" -ForegroundColor Yellow
                return $null
            }
        }
    }
    return $null
}

# Main script execution
try {
    # Auto stage all changes
    Write-Host "`n正在自动暂存所有变更..." -ForegroundColor Cyan
    git add -A
    if ($LASTEXITCODE -ne 0) {
        throw "无法暂存文件"
    }
    Write-Host "文件暂存成功" -ForegroundColor Green

    # Check staged changes
    Write-Host "`n开始检查Git变更..." -ForegroundColor Cyan
    $changes = Get-GitChanges
    if (-not $changes) {
        Write-Host "没有发现任何变更。" -ForegroundColor Yellow
        exit 0
    }
    
    # Display changes summary
    Write-Host "`n变更摘要：" -ForegroundColor Cyan
    Write-Host "新增文件: $($changes['added'].Count)" -ForegroundColor Green
    Write-Host "修改文件: $($changes['modified'].Count)" -ForegroundColor Yellow
    Write-Host "删除文件: $($changes['deleted'].Count)" -ForegroundColor Red    
    # Get detailed diff for LLM analysis
    $diffContent = Get-DetailedDiff    
    # Generate commit message using LLM
    Write-Host "`n正在使用LLM分析变更并生成commit消息..." -ForegroundColor Cyan
    $commitMessage = Get-LLMCommitMessage -diffContent $diffContent    
    if (-not $commitMessage) {
        $currentDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $commitMessage = "Daily backup: $currentDate"
        Write-Host "使用默认commit消息" -ForegroundColor Yellow
    }    
    Write-Host "`nCommit消息：" -ForegroundColor Cyan
    # 直接打印原始（格式化后）的消息
    # $decodedMessage = [System.Web.HttpUtility]::HtmlDecode($commitMessage)
    Write-Host $commitMessage -ForegroundColor Green    
    if ($DEBUG_MODE) {
        Write-Host "`n[调试模式] 跳过commit和push操作" -ForegroundColor Yellow
    } else {
        # 执行commit操作
        Write-Host "`n正在创建commit..." -ForegroundColor Cyan
        git commit -m $commitMessage > $null
        if ($LASTEXITCODE -ne 0) {
            throw "无法创建commit"
        }
        Write-Host "Commit创建成功" -ForegroundColor Green
        Write-Host "`n正在推送所有分支到远程..." -ForegroundColor Cyan
        git push --all origin > $null 2>&1  #do not show messages
        # git push --all origin             #normal show messages

        if ($LASTEXITCODE -ne 0) {
            throw "无法推送分支"
        }
        Write-Host "分支推送成功" -ForegroundColor Green
    }
    
    Write-Host "`n自动Git提交和推送完成！" -ForegroundColor Green
}
catch {
    Write-Host "`n错误：$_" -ForegroundColor Red
    Write-Host "自动Git提交和推送失败" -ForegroundColor Red
    exit 1
}