-- Embed the BibTeX records used by publications.qmd so the browser can reveal
-- a copy-ready record for each generated bibliography entry.

local function trim(value)
  return value:match("^%s*(.-)%s*$")
end

local function json_escape(value)
  return value:gsub("[\\\"\b\f\n\r\t]", {
    ["\\"] = "\\\\",
    ["\""] = "\\\"",
    ["\b"] = "\\b",
    ["\f"] = "\\f",
    ["\n"] = "\\n",
    ["\r"] = "\\r",
    ["\t"] = "\\t",
  }):gsub("</", "<\\/")
end

local function bib_entries(path)
  local file = assert(io.open(path, "r"), "Unable to read bibliography: " .. path)
  local source = file:read("*a")
  file:close()

  local entries = {}
  local position = 1

  while true do
    local start_at, after_open, entry_type, opener = source:find('@([%a]+)%s*([%{%(%"])', position)
    if not start_at then break end

    -- @comment, @preamble, and @string do not identify publication records.
    if entry_type:lower() ~= "comment" and entry_type:lower() ~= "preamble" and entry_type:lower() ~= "string" then
      local closing = opener == "{" and "}" or ")"
      local comma = source:find(",", after_open + 1, true)
      if comma then
        local key = trim(source:sub(after_open + 1, comma - 1))
        local depth, quote, escaped = 1, false, false
        local cursor = comma + 1

        while cursor <= #source and depth > 0 do
          local character = source:sub(cursor, cursor)
          if quote then
            if character == '"' and not escaped then quote = false end
            escaped = character == "\\" and not escaped
          else
            if character == '"' then
              quote = true
            elseif character == opener then
              depth = depth + 1
            elseif character == closing then
              depth = depth - 1
            end
          end
          cursor = cursor + 1
        end

        if key ~= "" and depth == 0 then
          entries[key] = source:sub(start_at, cursor - 1)
          position = cursor
        else
          position = after_open + 1
        end
      else
        position = after_open + 1
      end
    else
      position = after_open + 1
    end
  end

  return entries
end

-- Keep this list aligned with the named bibliography groups in publications.qmd.
-- The entries themselves are always read from these .bib source files at render time.
local bibliography_paths = {
  "_bibliography/theses.bib",
  "_bibliography/books.bib",
  "_bibliography/articles.bib",
  "_bibliography/proceedings.bib",
  "_bibliography/papers.bib",
  "_bibliography/tutorials.bib",
  "_bibliography/demos.bib",
  "_bibliography/wpapers.bib",
  "_bibliography/epapers.bib",
  "_bibliography/reports.bib",
}

function Pandoc(doc)
  local records = {}
  for _, path in ipairs(bibliography_paths) do
    for key, entry in pairs(bib_entries(path)) do
      records[key] = entry
    end
  end

  local encoded = {}
  for key, entry in pairs(records) do
    table.insert(encoded, '"' .. json_escape(key) .. '":"' .. json_escape(entry) .. '"')
  end

  table.sort(encoded)
  local data = table.concat(encoded, ",")
  local script = [[
<script id="publication-bibtex-data" type="application/json">{]] .. data .. [[}</script>
<script>
document.addEventListener("DOMContentLoaded", function () {
  var source = document.getElementById("publication-bibtex-data");
  if (!source) return;
  var entries = JSON.parse(source.textContent);
  document.querySelectorAll(".csl-entry[id^='ref-']").forEach(function (citation) {
    var key = citation.id.slice(4);
    var bibtex = entries[key];
    if (!bibtex) return;

    var toggle = document.createElement("button");
    toggle.type = "button";
    toggle.className = "publication-bib-toggle";
    toggle.textContent = "[bib]";
    toggle.setAttribute("aria-expanded", "false");
    toggle.setAttribute("aria-label", "Show BibTeX for " + key);

    var container = document.createElement("div");
    container.className = "publication-bib-entry";
    container.hidden = true;
    var code = document.createElement("code");
    code.textContent = bibtex;
    var block = document.createElement("pre");
    block.appendChild(code);
    var copy = document.createElement("button");
    copy.type = "button";
    copy.className = "publication-bib-copy";
    copy.setAttribute("aria-label", "Copy BibTeX for " + key);
    copy.setAttribute("title", "Copy BibTeX");
    copy.innerHTML = '<svg class="publication-bib-copy-icon" viewBox="0 0 16 16" aria-hidden="true"><path d="M0 6.75C0 5.784.784 5 1.75 5h7.5C10.216 5 11 5.784 11 6.75v7.5c0 .966-.784 1.75-1.75 1.75h-7.5A1.75 1.75 0 0 1 0 14.25ZM1.75 6.5a.25.25 0 0 0-.25.25v7.5c0 .138.112.25.25.25h7.5a.25.25 0 0 0 .25-.25v-7.5a.25.25 0 0 0-.25-.25Z"></path><path d="M5 1.75C5 .784 5.784 0 6.75 0h7.5C15.216 0 16 .784 16 1.75v7.5A1.75 1.75 0 0 1 14.25 11H13V9.5h1.25a.25.25 0 0 0 .25-.25v-7.5a.25.25 0 0 0-.25-.25h-7.5a.25.25 0 0 0-.25.25V3H5Z"></path></svg><svg class="publication-bib-check-icon" viewBox="0 0 16 16" aria-hidden="true"><path d="m13.78 3.97-7.25 7.25a.75.75 0 0 1-1.06 0L2.22 7.97l1.06-1.06L6 9.63l6.72-6.72Z"></path></svg>';
    copy.addEventListener("click", function () {
      navigator.clipboard.writeText(bibtex).then(function () {
        copy.classList.add("is-copied");
        copy.setAttribute("aria-label", "Copied BibTeX for " + key);
        copy.setAttribute("title", "Copied!");
        window.setTimeout(function () {
          copy.classList.remove("is-copied");
          copy.setAttribute("aria-label", "Copy BibTeX for " + key);
          copy.setAttribute("title", "Copy BibTeX");
        }, 1500);
      });
    });
    container.appendChild(copy);
    container.appendChild(block);

    toggle.addEventListener("click", function () {
      var visible = container.hidden;
      container.hidden = !visible;
      toggle.setAttribute("aria-expanded", String(visible));
      toggle.setAttribute("aria-label", (visible ? "Hide" : "Show") + " BibTeX for " + key);
    });

    citation.appendChild(toggle);
    citation.appendChild(container);
  });
});
</script>]]

  table.insert(doc.blocks, pandoc.RawBlock("html", script))
  return doc
end
