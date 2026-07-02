# Literature Search：学术文献检索 Skill

这是一个面向 Codex 的学术文献检索 Skill，用于检索、核验、去重和整理中英文文献，并输出可审计的 BibTeX 与 LaTeX 文献目录。

## 主要功能

- 优先使用 Scopus，并支持 Google Scholar、Crossref、Semantic Scholar、OpenAlex、arXiv、IEEE Xplore、Elsevier ScienceDirect、SpringerLink、中国知网和万方；Web of Science 可访问时作为补充来源。
- 逐篇核验题名、作者、出版年份、期刊或会议、卷期页码及 DOI，禁止编造文献或通过猜测补全 DOI。
- 默认返回不少于 101 篇经过核验和去重的文献。
- 默认中文文献不少于最终文献总数的 30%。
- 默认近五年文献不少于最终文献总数的 30%。
- 对文献进行主题相关性、证据质量和版本关系标记。
- 合并预印本、会议版、在线优先版和正式期刊版等重复版本。
- 输出包含摘要或明确标记的摘要概述，并记录摘要来源。
- 使用 MATLAB 脚本审计数量、比例、必填字段、引用键、DOI 和出版信息。
- 默认不生成 Excel、XLSX 或 CSV 文件，除非用户明确要求。

## 安装方法

将仓库中的 `literature-search` 文件夹复制到 Codex Skill 目录：

```text
~/.codex/skills/literature-search
```

Windows 默认位置通常为：

```text
C:\Users\<用户名>\.codex\skills\literature-search
```

安装后使用以下命令调用：

```text
$literature-search
```

## 使用示例

```text
使用 $literature-search 查找锂离子电池热失控预警相关文献。
```

也可以指定数量和比例：

```text
使用 $literature-search 查找 150 篇海上风电故障诊断文献，
要求中文文献不少于 40%，近三年文献不少于 50%。
```

## 默认输出

- `literature_references.bib`：经过核验和去重的 BibTeX 数据库。
- `literature_catalog.tex`：包含检索信息、配额统计、完整文献元数据、DOI、摘要和核验来源的 LaTeX 文档。

LaTeX 文档采用英文文件名、UTF-8 编码、`ctex` 和 XeLaTeX。Skill 会进行编译验证；只有在用户明确要求时才交付 PDF。

## DOI 与摘要规则

- 主文献列表中的 DOI 必须能够解析，并与题名、作者、出版物及年份相匹配。
- 不得根据出版社格式猜测或拼接 DOI。
- 无法核验 DOI 的文献不计入默认文献数量及比例。
- 摘要必须来自出版社、Scopus、学术数据库、机构知识库或正式文献记录。
- 无法合法保留原始摘要时，使用基于已核验摘要撰写的简明概述，并标记为摘要概述。
- 对尚未分配卷、期或页码的在线优先论文，应明确注明，禁止虚构出版信息。

## MATLAB 审计

审计脚本位于：

```text
literature-search/scripts/audit_literature_bib.m
```

默认审计示例：

```matlab
addpath("literature-search/scripts");
result = audit_literature_bib( ...
    "literature_references.bib", ...
    "literature_audit.txt");
```

指定目标数量和比例：

```matlab
result = audit_literature_bib( ...
    "literature_references.bib", ...
    "literature_audit.txt", ...
    TargetCount=150, ...
    ChineseRatio=0.40, ...
    RecentRatio=0.50);
```

审计失败时，应修正文献数据后重新运行，不得使用未核验或虚假文献补足数量。
