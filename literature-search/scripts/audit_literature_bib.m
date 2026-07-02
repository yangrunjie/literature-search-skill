function result = audit_literature_bib(bibFile, reportFile, options)
%AUDIT_LITERATURE_BIB 审计文献检索 Skill 生成的 BibTeX 数据库。
%   RESULT = AUDIT_LITERATURE_BIB(BIBFILE) 检查条目数、必填字段、
%   DOI 与引用键唯一性、中文文献比例及近五年文献比例。
%   AUDIT_LITERATURE_BIB(BIBFILE, REPORTFILE) 另外保存 UTF-8 文本报告。

arguments
    bibFile (1, 1) string
    reportFile (1, 1) string = ""
    options.TargetCount (1, 1) double {mustBeInteger, mustBeNonnegative} = 101
    options.ChineseRatio (1, 1) double {mustBeInRange(options.ChineseRatio, 0, 1)} = 0.30
    options.RecentRatio (1, 1) double {mustBeInRange(options.RecentRatio, 0, 1)} = 0.30
end

if ~isfile(bibFile)
    error("audit_literature_bib:FileNotFound", "找不到 BibTeX 文件：%s", bibFile);
end

raw = fileread(bibFile);
entries = parseEntries(raw);
n = numel(entries);
required = ["author", "title", "year", "doi", "url", "abstract", ...
    "language", "abstractsource", "abstracttype"];

issues = strings(0, 1);
keys = strings(n, 1);
dois = strings(n, 1);
isChinese = false(n, 1);
isRecent = false(n, 1);
currentYear = year(datetime("today"));

for i = 1:n
    entry = entries(i);
    keys(i) = lower(strtrim(entry.key));

    for fieldName = required
        if ~isfield(entry.fields, fieldName) || strlength(strtrim(entry.fields.(fieldName))) == 0
            issues(end + 1) = sprintf("[%s] 缺少必填字段：%s", entry.key, fieldName); %#ok<AGROW>
        end
    end

    if isfield(entry.fields, "doi")
        dois(i) = normalizeDoi(entry.fields.doi);
        if strlength(dois(i)) == 0
            issues(end + 1) = sprintf("[%s] DOI 为空或格式无效", entry.key); %#ok<AGROW>
        end
    end

    if isfield(entry.fields, "language")
        language = lower(stripValue(entry.fields.language));
        isChinese(i) = startsWith(language, "zh") || contains(language, "chinese") ...
            || contains(language, "中文") || contains(language, "汉语");
    end

    if isfield(entry.fields, "year")
        y = str2double(regexp(stripValue(entry.fields.year), "\d{4}", "match", "once"));
        if isnan(y)
            issues(end + 1) = sprintf("[%s] 年份无法解析", entry.key); %#ok<AGROW>
        else
            isRecent(i) = y >= currentYear - 4 && y <= currentYear;
        end
    end

    if entry.type == "article"
        missingPublicationData = ~isfield(entry.fields, "volume") ...
            || ~isfield(entry.fields, "number") || ~isfield(entry.fields, "pages");
        hasExplanation = isfield(entry.fields, "note") && ...
            (contains(lower(entry.fields.note), "online first") ...
            || contains(lower(entry.fields.note), "not assigned") ...
            || contains(entry.fields.note, "未分配"));
        if missingPublicationData && ~hasExplanation
            issues(end + 1) = sprintf("[%s] 期刊论文缺少卷/期/页码且无未分配说明", entry.key); %#ok<AGROW>
        end
    end
end

issues = [issues; duplicateIssues(keys, "引用键"); duplicateIssues(dois, "DOI")];
requiredChinese = ceil(options.ChineseRatio * n);
requiredRecent = ceil(options.RecentRatio * n);
actualChinese = nnz(isChinese);
actualRecent = nnz(isRecent);

if n < options.TargetCount
    issues(end + 1) = sprintf("目标要求至少 %d 篇，当前为 %d 篇", options.TargetCount, n);
end
if actualChinese < requiredChinese
    issues(end + 1) = sprintf("中文文献不足：要求至少 %d 篇，当前 %d 篇", requiredChinese, actualChinese);
end
if actualRecent < requiredRecent
    issues(end + 1) = sprintf("近五年文献不足：要求至少 %d 篇，当前 %d 篇", requiredRecent, actualRecent);
end

result = struct( ...
    "valid", isempty(issues), ...
    "entryCount", n, ...
    "chineseCount", actualChinese, ...
    "chineseRequired", requiredChinese, ...
    "recentCount", actualRecent, ...
    "recentRequired", requiredRecent, ...
    "issues", issues);

report = composeReport(result);
fprintf("%s", report);
if strlength(reportFile) > 0
    fid = fopen(reportFile, "w", "n", "UTF-8");
    if fid < 0
        error("audit_literature_bib:ReportWriteFailed", "无法写入报告：%s", reportFile);
    end
    cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
    fprintf(fid, "%s", report);
end

if nargout == 0 && ~result.valid
    error("audit_literature_bib:AuditFailed", "BibTeX 审计失败，共发现 %d 个问题。", numel(issues));
end
end

function entries = parseEntries(raw)
% 逐字符识别顶层 BibTeX 条目，避免摘要内部花括号干扰。
raw = string(raw);
entries = struct("type", {}, "key", {}, "fields", {});
i = 1;
while i <= strlength(raw)
    atRel = regexp(extractAfter(raw, i - 1), "@", "once");
    if isempty(atRel)
        break;
    end
    at = atRel + i - 1;
    tail = extractAfter(raw, at);
    openRel = regexp(tail, "[\{\(]", "once");
    if isempty(openRel)
        break;
    end
    openPos = at + openRel;
    type = lower(strtrim(extractBetween(raw, at + 1, openPos - 1)));
    [closePos, ok] = matchingDelimiter(raw, openPos);
    if ~ok
        error("audit_literature_bib:UnbalancedEntry", "BibTeX 条目存在未配对括号，位置 %d。", at);
    end
    body = extractBetween(raw, openPos + 1, closePos - 1);
    parts = splitTopLevel(body);
    if isempty(parts)
        i = closePos + 1;
        continue;
    end
    key = strtrim(parts(1));
    fields = struct();
    for p = 2:numel(parts)
        token = parts(p);
        eq = regexp(token, "=", "once");
        if isempty(eq)
            continue;
        end
        name = lower(strtrim(extractBefore(token, eq)));
        if ~isvarname(name)
            continue;
        end
        fields.(name) = strtrim(extractAfter(token, eq));
    end
    entries(end + 1) = struct("type", type, "key", key, "fields", fields); %#ok<AGROW>
    i = closePos + 1;
end
end

function [closePos, ok] = matchingDelimiter(raw, openPos)
opener = extractBetween(raw, openPos, openPos);
closer = "}";
if opener == "("
    closer = ")";
end
depth = 0;
quoted = false;
escaped = false;
ok = false;
closePos = openPos;
for j = openPos:strlength(raw)
    c = extractBetween(raw, j, j);
    if escaped
        escaped = false;
        continue;
    end
    if c == "\"
        escaped = true;
    elseif c == '"'
        quoted = ~quoted;
    elseif ~quoted && c == opener
        depth = depth + 1;
    elseif ~quoted && c == closer
        depth = depth - 1;
        if depth == 0
            closePos = j;
            ok = true;
            return;
        end
    end
end
end

function parts = splitTopLevel(body)
parts = strings(0, 1);
startPos = 1;
depth = 0;
quoted = false;
escaped = false;
for j = 1:strlength(body)
    c = extractBetween(body, j, j);
    if escaped
        escaped = false;
        continue;
    end
    if c == "\"
        escaped = true;
    elseif c == '"'
        quoted = ~quoted;
    elseif ~quoted && (c == "{" || c == "(")
        depth = depth + 1;
    elseif ~quoted && (c == "}" || c == ")")
        depth = depth - 1;
    elseif ~quoted && depth == 0 && c == ","
        parts(end + 1) = strtrim(extractBetween(body, startPos, j - 1)); %#ok<AGROW>
        startPos = j + 1;
    end
end
parts(end + 1) = strtrim(extractAfter(body, startPos - 1));
parts(parts == "") = [];
end

function value = stripValue(value)
value = strtrim(string(value));
while strlength(value) >= 2
    first = extractBetween(value, 1, 1);
    last = extractBetween(value, strlength(value), strlength(value));
    if (first == "{" && last == "}") || (first == '"' && last == '"')
        value = strtrim(extractBetween(value, 2, strlength(value) - 1));
    else
        break;
    end
end
end

function doi = normalizeDoi(value)
doi = lower(stripValue(value));
doi = regexprep(doi, "^https?://(dx\.)?doi\.org/", "");
doi = regexprep(doi, "^doi:\s*", "");
doi = regexprep(doi, "[\s\.,;]+$", "");
if isempty(regexp(doi, "^10\.\d{4,9}/\S+$", "once"))
    doi = "";
end
end

function issues = duplicateIssues(values, label)
issues = strings(0, 1);
values = values(values ~= "");
if isempty(values)
    return;
end
[uniqueValues, ~, groups] = unique(values);
counts = accumarray(groups, 1);
for i = find(counts > 1)'
    issues(end + 1) = sprintf("%s 重复：%s（%d 次）", label, uniqueValues(i), counts(i)); %#ok<AGROW>
end
end

function report = composeReport(result)
status = "通过";
if ~result.valid
    status = "失败";
end
lines = [ ...
    "BibTeX 文献审计报告", ...
    "状态：" + status, ...
    "条目数：" + result.entryCount, ...
    sprintf("中文文献：%d / 至少 %d", result.chineseCount, result.chineseRequired), ...
    sprintf("近五年文献：%d / 至少 %d", result.recentCount, result.recentRequired), ...
    "问题数：" + numel(result.issues)];
if ~isempty(result.issues)
    lines = [lines, "问题：", "- " + result.issues']; %#ok<AGROW>
end
report = strjoin(lines, newline) + newline;
end
