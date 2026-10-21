#!/bin/bash

# Read the JSON payload from stdin
input=$(cat)

if command -v jq >/dev/null 2>&1; then
  # 1. Active Model
  model=$(echo "$input" | jq -r '.model.display_name // "Unknown Model"')

  # 2. Workspace & CWD
  cwd=$(echo "$input" | jq -r '.cwd // .workspace.current_dir // ""')

  # 3. Context Usage
  context_pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
  context_tokens=$(echo "$input" | jq -r '((.context_window.total_input_tokens // 0) + (.context_window.total_output_tokens // 0)) // empty')
  context_limit=$(echo "$input" | jq -r '.context_window.context_window_size // .context_window.limit // empty')

  # 4. Token Quota & Rate Limits
  gemini_5h_pct=$(echo "$input" | jq -r '
    (.quota["gemini-5h"].remaining_fraction // empty) as $rem
    | if $rem != null and $rem != "" then (1 - ($rem | tonumber)) * 100 else empty end
  ')

  gemini_7d_pct=$(echo "$input" | jq -r '
    (.quota["gemini-weekly"].remaining_fraction // empty) as $rem
    | if $rem != null and $rem != "" then (1 - ($rem | tonumber)) * 100 else empty end
  ')

  claude_5h_pct=$(echo "$input" | jq -r '
    (.quota["3p-5h"].remaining_fraction // .quota["claude-5h"].remaining_fraction // .quota["3p-claude-5h"].remaining_fraction // empty) as $rem
    | if $rem != null and $rem != "" then (1 - ($rem | tonumber)) * 100 else empty end
  ')

  claude_7d_pct=$(echo "$input" | jq -r '
    (.quota["3p-weekly"].remaining_fraction // .quota["claude-weekly"].remaining_fraction // .quota["3p-claude-weekly"].remaining_fraction // empty) as $rem
    | if $rem != null and $rem != "" then (1 - ($rem | tonumber)) * 100 else empty end
  ')

  extra_quotas=$(echo "$input" | jq -r '
    .quota // {} | to_entries
    | map(
        select(.key | test("^(gemini|3p|claude|3p-claude)-(5h|weekly)$") | not)
        | select(.value.remaining_fraction != null and .value.remaining_fraction != "")
        | (
            if (.key | test("argon|pro")) then "Pro"
            elif (.key | test("wtu")) then "WTU"
            elif (.key | test("opus")) then "Claude-Opus"
            elif (.key | test("sonnet")) then "Claude-Sonnet"
            elif (.key | test("claude")) then "Claude"
            else (.key | sub("^(gemini|3p|claude)-"; "") | sub("-(weekly|5h)$"; ""))
            end
          ) as $name
        | {name: $name, pct: ((1 - (.value.remaining_fraction | tonumber)) * 100)}
      )
    | group_by(.name)
    | map({name: .[0].name, pct: (map(.pct) | max)})
    | .[]
    | "\(.name):\(.pct)"
  ')

  general_quota=$(echo "$input" | jq -r '.quota.used_percentage // .usage.used_percentage // empty')
else
  eval "$(python3 -c '
import json, shlex, sys
try:
    d = json.loads(sys.stdin.read() or "{}")
except Exception:
    d = {}
model = (d.get("model") or {}).get("display_name") or "Unknown Model"
cwd = d.get("cwd") or (d.get("workspace") or {}).get("current_dir") or ""
cw = d.get("context_window") or {}
context_pct = cw.get("used_percentage") if cw.get("used_percentage") is not None else 0
in_tok = cw.get("total_input_tokens") or 0
out_tok = cw.get("total_output_tokens") or 0
context_tokens = in_tok + out_tok
context_limit = cw.get("context_window_size") or cw.get("limit") or ""
q = d.get("quota") or {}

def get_rem_pct(keys):
    for k in keys:
        v = (q.get(k) or {}).get("remaining_fraction")
        if v is not None and v != "":
            try:
                return str((1.0 - float(v)) * 100.0)
            except Exception:
                pass
    return ""

gemini_5h_pct = get_rem_pct(["gemini-5h"])
gemini_7d_pct = get_rem_pct(["gemini-weekly"])
claude_5h_pct = get_rem_pct(["3p-5h", "claude-5h", "3p-claude-5h"])
claude_7d_pct = get_rem_pct(["3p-weekly", "claude-weekly", "3p-claude-weekly"])

base_keys = {
    "gemini-5h", "gemini-weekly",
    "3p-5h", "3p-weekly",
    "claude-5h", "claude-weekly",
    "3p-claude-5h", "3p-claude-weekly"
}
extra_dict = {}
for k, v in q.items():
    if k in base_keys or not isinstance(v, dict):
        continue
    rem = v.get("remaining_fraction")
    if rem is not None and rem != "":
        try:
            pct = (1.0 - float(rem)) * 100.0
            k_lower = k.lower()
            if "argon" in k_lower or "pro" in k_lower:
                name = "Pro"
            elif "wtu" in k_lower:
                name = "WTU"
            elif "opus" in k_lower:
                name = "Claude-Opus"
            elif "sonnet" in k_lower:
                name = "Claude-Sonnet"
            elif "claude" in k_lower:
                name = "Claude"
            else:
                name = k
                for p in ["gemini-", "3p-", "claude-"]:
                    if name.startswith(p):
                        name = name[len(p):]
                for s in ["-weekly", "-5h"]:
                    if name.endswith(s):
                        name = name[:-len(s)]
            if name not in extra_dict or pct > extra_dict[name]:
                extra_dict[name] = pct
        except Exception:
            pass
extra_quotas = "\n".join(f"{name}:{pct}" for name, pct in extra_dict.items())
general_quota = q.get("used_percentage")
if general_quota is None:
    general_quota = (d.get("usage") or {}).get("used_percentage")
general_quota = "" if general_quota is None else str(general_quota)
for k, v in [
    ("model", str(model)),
    ("cwd", str(cwd)),
    ("context_pct", str(context_pct)),
    ("context_tokens", str(context_tokens)),
    ("context_limit", str(context_limit)),
    ("gemini_5h_pct", str(gemini_5h_pct)),
    ("gemini_7d_pct", str(gemini_7d_pct)),
    ("claude_5h_pct", str(claude_5h_pct)),
    ("claude_7d_pct", str(claude_7d_pct)),
    ("extra_quotas", str(extra_quotas)),
    ("general_quota", str(general_quota)),
]:
    print(f"{k}={shlex.quote(v)}")
' <<< "$input")"
fi

if [ -z "$cwd" ]; then
  cwd=$(pwd)
fi

# Prettify the CWD (abbreviate home folder to ~)
cwd_pretty="${cwd/#$HOME/\~}"

# Workspace session name (basename of current working directory)
session_name=$(basename "$cwd")
if [ -z "$session_name" ] || [ "$session_name" = "/" ]; then
  session_name="root"
fi

# Git Branch name if inside a git repository
git_branch=""
if [ -d "$cwd/.git" ] || git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git_branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)
fi

# Construct a nice display name for the session
if [ -n "$git_branch" ]; then
  session_display="${session_name} (${git_branch})"
else
  session_display="${session_name}"
fi

context_pct_int=$(printf "%.0f" "$context_pct" 2>/dev/null || echo 0)

# Choose color based on context threshold (Green < 50%, Yellow 50-80%, Red >= 80%)
if [ "$context_pct_int" -lt 50 ]; then
  color_ctx="\033[32m" # Green
elif [ "$context_pct_int" -lt 80 ]; then
  color_ctx="\033[33m" # Yellow
else
  color_ctx="\033[31m" # Red
fi

# Render context bar (10 blocks)
filled=$(( (context_pct_int + 5) / 10 ))
if [ $filled -gt 10 ]; then filled=10; fi
if [ $filled -lt 0 ]; then filled=0; fi
empty=$(( 10 - filled ))
bar=""
for ((i=0; i<filled; i++)); do bar="${bar}■"; done
for ((i=0; i<empty; i++)); do bar="${bar}░"; done

# Build detailed context label
if [ -n "$context_tokens" ] && [ -n "$context_limit" ] && [ "$context_tokens" != "null" ] && [ "$context_limit" != "null" ]; then
  # Format numbers in K (thousands) for clean display if they are large
  if [ "$context_limit" -ge 1000 ]; then
    tokens_k=$(( context_tokens / 1000 ))
    limit_k=$(( context_limit / 1000 ))
    ctx_label="${tokens_k}k/${limit_k}k"
  else
    ctx_label="${context_tokens}/${context_limit}"
  fi
  context_info="${color_ctx}${bar} ${context_pct_int}% (${ctx_label})\033[0m"
else
  context_info="${color_ctx}${bar} ${context_pct_int}%\033[0m"
fi

quota_info=""

format_quota_item() {
  local label="$1"
  local val="$2"
  if [ -n "$val" ] && [ "$val" != "null" ] && [ "$val" != "" ]; then
    local val_int
    val_int=$(printf "%.0f" "$val" 2>/dev/null || echo 0)
    local color
    if [ "$val_int" -lt 50 ]; then
      color="\033[32m"
    elif [ "$val_int" -lt 80 ]; then
      color="\033[33m"
    else
      color="\033[31m"
    fi
    if [ -n "$quota_info" ]; then
      quota_info="${quota_info} | "
    fi
    quota_info="${quota_info}${label}: ${color}${val_int}%\033[0m"
  fi
}

model_lower=$(echo "$model" | tr '[:upper:]' '[:lower:]')
if [[ "$model_lower" =~ claude ]] || [[ "$model_lower" =~ anthropic ]]; then
  format_quota_item "Claude 5h" "$claude_5h_pct"
  format_quota_item "Claude 7d" "$claude_7d_pct"
  format_quota_item "Gemini 5h" "$gemini_5h_pct"
  format_quota_item "Gemini 7d" "$gemini_7d_pct"
else
  format_quota_item "5h" "$gemini_5h_pct"
  format_quota_item "7d" "$gemini_7d_pct"
  format_quota_item "Claude 5h" "$claude_5h_pct"
  format_quota_item "Claude 7d" "$claude_7d_pct"
fi

if [ -n "$extra_quotas" ]; then
  while IFS=':' read -r eq_name eq_pct; do
    [ -z "$eq_name" ] || [ -z "$eq_pct" ] && continue
    format_quota_item "$eq_name" "$eq_pct"
  done <<< "$extra_quotas"
fi

# If no rate limit info found in the JSON payload, check for any general quota keys or fall back
if [ -z "$quota_info" ]; then
  if [ -n "$general_quota" ] && [ "$general_quota" != "null" ] && [ "$general_quota" != "" ]; then
    general_quota_int=$(printf "%.0f" "$general_quota" 2>/dev/null || echo 0)
    quota_info="Quota: ${general_quota_int}%"
  else
    quota_info="Quota: \033[36mN/A\033[0m"
  fi
else
  quota_info="Quota [${quota_info}]"
fi

# Print the formatted status line with clean separation and styling
echo -e "\033[36m●\033[0m \033[1m${session_display}\033[0m \033[90m(${cwd_pretty})\033[0m | \033[35m${model}\033[0m | Context: ${context_info} | ${quota_info}"
