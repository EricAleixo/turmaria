import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  // não precisamos declarar targets obrigatórios — iremos buscar por ID como no original,
  // mas você pode adicionar data-targets se preferir.
  connect() {
    // marca pra debugging
    // console.log("ConteudoController conectado");

    // Guardas de listeners para remover no disconnect
    this._listeners = [];

    // ------ helpers para adicionar/remover listeners com referência ------
    const addDocListener = (evt, fn, opts) => {
      document.addEventListener(evt, fn, opts);
      this._listeners.push({ node: document, evt, fn, opts });
    };
    const addElListener = (el, evt, fn, opts) => {
      el.addEventListener(evt, fn, opts);
      this._listeners.push({ node: el, evt, fn, opts });
    };

    // ====== TURBO: BEFORE-CACHE cleanup handler (mantém comportamento do seu script) ======
    this._beforeCacheHandler = () => {
      const container = document.getElementById("editor-container");
      if (container) {
        delete container.dataset.initialized;
        container.innerHTML = "";
      }

      const toolbar = document.getElementById("floating-toolbar");
      if (toolbar) toolbar.classList.remove("show");

      const headingMenu = document.getElementById("heading-menu");
      const sizeMenu = document.getElementById("size-menu");
      if (headingMenu) headingMenu.classList.remove("show");
      if (sizeMenu) sizeMenu.classList.remove("show");
    };
    addDocListener("turbo:before-cache", this._beforeCacheHandler);

    // ====== Inicialização principal (substitui turbo:load) ======
    // Pegamos elementos por id exatamente como no seu código para preservar tudo.
    const textarea = document.getElementById("markdown-field");
    let container = document.getElementById("editor-container");
    const toolbar = document.getElementById("floating-toolbar");
    const headingBtn = document.getElementById("heading-btn");
    const headingMenu = document.getElementById("heading-menu");
    const sizeBtn = document.getElementById("size-btn");
    const sizeMenu = document.getElementById("size-menu");

    if (!textarea || !container) {
      // não inicializa se não existir; evita erros em páginas que não tem editor
      // console.warn("ConteudoController: textarea ou container não encontrado — não inicializando editor.");
      return;
    }

    // Remove listeners antigos clonando o elemento (como no seu script)
    if (container.dataset.initialized === "true") {
      const clone = container.cloneNode(false);
      container.parentNode.replaceChild(clone, container);
      container = clone;
    }

    container.dataset.initialized = "true";

    let currentRange = null;

    // ============ CONVERSÃO MARKDOWN ============
    // Mantive as mesmas regex/objetos do seu script (sem alterações funcionais)
    const mdPatterns = {
      h6: { md: /^###### (.*$)/gim, html: "<h6>$1</h6>" },
      h5: { md: /^##### (.*$)/gim, html: "<h5>$1</h5>" },
      h4: { md: /^#### (.*$)/gim, html: "<h4>$1</h4>" },
      h3: { md: /^### (.*$)/gim, html: "<h3>$1</h3>" },
      h2: { md: /^## (.*$)/gim, html: "<h2>$1</h2>" },
      h1: { md: /^# (.*$)/gim, html: "<h1>$1</h1>" },
      bold: { md: /\*\*(.*?)\*\*/g, html: "<strong>$1</strong>" },
      italic: { md: /\*(.*?)\*/g, html: "<em>$1</em>" },
      strike: { md: /~~(.*?)~~/g, html: "<s>$1</s>" },
      code: { md: /`(.*?)`/g, html: "<code>$1</code>" },
      quote: { md: /^> (.*$)/gim, html: "<blockquote>$1</blockquote>" },
      ulItem: { md: /^- (.*$)/gim, html: "<li>$1</li>" },
      olItem: { md: /^\d+\. (.*$)/gim, html: "<li>$1</li>" }
    };

    const htmlPatterns = {
      h1: /<h1>(.*?)<\/h1>/gi,
      h2: /<h2>(.*?)<\/h2>/gi,
      h3: /<h3>(.*?)<\/h3>/gi,
      h4: /<h4>(.*?)<\/h4>/gi,
      h5: /<h5>(.*?)<\/h5>/gi,
      h6: /<h6>(.*?)<\/h6>/gi,
      strong: /<(?:strong|b)>(.*?)<\/(?:strong|b)>/gi,
      em: /<(?:em|i)>(.*?)<\/(?:em|i)>/gi,
      s: /<s>(.*?)<\/s>/gi,
      code: /<code>(.*?)<\/code>/gi,
      quote: /<blockquote>(.*?)<\/blockquote>/gi
    };

    const autoFormats = {
      h6: /^######\s$/,
      h5: /^#####\s$/,
      h4: /^####\s$/,
      h3: /^###\s$/,
      h2: /^##\s$/,
      h1: /^#\s$/,
      quote: /^>\s$/,
      bulletList: /^-\s$/,
      numberedList: /^\d+\.\s$/
    };

    const inlineFormats = [
      { pattern: /\*\*([^*]+)\*\*(?=\s|$)/, tag: "strong" },
      { pattern: /(?<!\*)\*([^*]+)\*(?!\*)(?=\s|$)/, tag: "em" },
      { pattern: /~~([^~]+)~~(?=\s|$)/, tag: "s" },
      { pattern: /`([^`]+)`(?=\s|$)/, tag: "code" }
    ];

    // Funções de conversão (idênticas ao original)
    const htmlToMarkdown = (html) => {
      let md = html;

      Object.entries(htmlPatterns).forEach(([key, pattern]) => {
        const prefix = { h1: "# ", h2: "## ", h3: "### ", h4: "#### ", h5: "##### ", h6: "###### " }[key] || "";
        const wrapper = { strong: "**", em: "*", s: "~~", code: "`", quote: "> " }[key] || "";

        if (prefix) md = md.replace(pattern, `${prefix}$1\n\n`);
        else if (wrapper) md = md.replace(pattern, wrapper === "> " ? `> $1\n\n` : `${wrapper}$1${wrapper}`);
      });

      md = md.replace(/<ul>(.*?)<\/ul>/gis, (_, content) => {
        return content.replace(/<li>(.*?)<\/li>/gi, "- $1\n");
      });

      md = md.replace(/<ol>(.*?)<\/ol>/gis, (_, content) => {
        let counter = 1;
        return content.replace(/<li>(.*?)<\/li>/gi, (_, item) => `${counter++}. ${item}\n`);
      });

      md = md.replace(/<span class="text-small">(.*?)<\/span>/gi, "$1");
      md = md.replace(/<span class="text-large">(.*?)<\/span>/gi, "$1");

      md = md.replace(/<p>(.*?)<\/p>/gi, "$1\n\n");
      md = md.replace(/<br\s*\/?>/gi, "\n");
      md = md.replace(/<div>(.*?)<\/div>/gi, "$1\n");
      md = md.replace(/<[^>]+>/g, "");

      return md.replace(/\n{3,}/g, "\n\n").trim();
    };

    const markdownToHtml = (md) => {
      let html = md;

      Object.values(mdPatterns).forEach(({ md: pattern, html: replacement }) => {
        html = html.replace(pattern, replacement);
      });

      html = html.replace(/(<li>.*?<\/li>\s*)+/gs, (match) => {
        if (!match.includes("<ol>") && !match.includes("<ul>")) {
          return `<ul>${match}</ul>`;
        }
        return match;
      });

      html = html
        .split("\n\n")
        .map((p) => {
          p = p.trim();
          if (!p) return "";
          if (p.startsWith("<") && (p.includes("<h") || p.includes("<ul") || p.includes("<ol") || p.includes("<blockquote"))) {
            return p;
          }
          return `<p>${p}</p>`;
        })
        .join("");

      return html;
    };

    const updateMarkdown = () => {
      textarea.value = htmlToMarkdown(container.innerHTML);
    };

    const selectNode = (node) => {
      const range = document.createRange();
      const sel = window.getSelection();
      range.setStart(node.firstChild || node, 0);
      range.collapse(true);
      sel.removeAllRanges();
      sel.addRange(range);
    };

    // Funções automáticas
    const convertToHeading = (tag, textNode, cursorPos) => {
      const heading = document.createElement(tag);
      heading.textContent = textNode.textContent.substring(cursorPos);

      const parent = textNode.parentElement;
      (parent.tagName === "P" ? parent : textNode).replaceWith(heading);

      selectNode(heading);
      updateMarkdown();
    };

    const convertToBlockquote = (textNode, cursorPos) => {
      const blockquote = document.createElement("blockquote");
      blockquote.textContent = textNode.textContent.substring(cursorPos);

      const parent = textNode.parentElement;
      (parent.tagName === "P" ? parent : textNode).replaceWith(blockquote);

      selectNode(blockquote);
      updateMarkdown();
    };

    const convertToList = (textNode, cursorPos, isOrdered) => {
      const listTag = isOrdered ? "ol" : "ul";
      const list = document.createElement(listTag);
      const li = document.createElement("li");
      li.textContent = textNode.textContent.substring(cursorPos);
      list.appendChild(li);

      const parent = textNode.parentElement;

      const existingList = parent.closest("ul, ol");
      if (existingList && existingList.tagName.toLowerCase() === listTag) {
        existingList.appendChild(li);
        (parent.tagName === "LI" ? parent : textNode).remove();
      } else {
        (parent.tagName === "P" ? parent : textNode).replaceWith(list);
      }

      selectNode(li);
      updateMarkdown();
    };

    const replaceWithFormatted = (textNode, match, tag) => {
      const parent = textNode.parentElement;
      const text = textNode.textContent;

      const fragment = document.createDocumentFragment();
      if (match.index) fragment.appendChild(document.createTextNode(text.substring(0, match.index)));

      const formatted = document.createElement(tag);
      formatted.textContent = match[1];
      fragment.appendChild(formatted);

      const after = text.substring(match.index + match[0].length);
      if (after) fragment.appendChild(document.createTextNode(after));

      parent.replaceChild(fragment, textNode);

      const range = document.createRange();
      range.setStartAfter(formatted);
      range.collapse(true);
      const sel = window.getSelection();
      sel.removeAllRanges();
      sel.addRange(range);

      updateMarkdown();
    };

    // Carrega conteúdo inicial DEPOIS de declarar todas as funções
    if (textarea.value) {
      container.innerHTML = markdownToHtml(textarea.value);
    }

    // ============ FORMATAÇÃO AUTOMÁTICA ============
    const handleInput = (e) => {
      const sel = window.getSelection();
      if (!sel.rangeCount) return updateMarkdown();

      const range = sel.getRangeAt(0);
      const textNode = range.startContainer;

      if (textNode.nodeType !== Node.TEXT_NODE) return updateMarkdown();

      const text = textNode.textContent;
      const cursorPos = range.startOffset;
      const beforeCursor = text.substring(0, cursorPos);

      for (const [type, pattern] of Object.entries(autoFormats)) {
        if (pattern.test(beforeCursor)) {
          e.preventDefault();
          if (type === "bulletList") convertToList(textNode, cursorPos, false);
          else if (type === "numberedList") convertToList(textNode, cursorPos, true);
          else if (type === "quote") convertToBlockquote(textNode, cursorPos);
          else convertToHeading(type, textNode, cursorPos);
          return;
        }
      }

      for (const { pattern, tag } of inlineFormats) {
        const match = text.match(pattern);
        if (match && match.index + match[0].length <= cursorPos) {
          replaceWithFormatted(textNode, match, tag);
          return;
        }
      }

      updateMarkdown();
    };

    // adiciona listener ao container e guarda referência para remover depois
    addElListener(container, "input", handleInput);

    const handlePaste = (e) => {
      e.preventDefault();
      document.execCommand("insertText", false, e.clipboardData.getData("text/plain"));
    };
    addElListener(container, "paste", handlePaste);

    // ============ TOOLBAR ============
    const showToolbar = () => {
      const selection = window.getSelection();
      if (!selection.rangeCount) return;
          
      const range = selection.getRangeAt(0);
      const rect = range.getBoundingClientRect();
          
      // Seleciona o form mais próximo do editor
      const form = toolbar.closest("form");
      if (!form) return;
          
      const formRect = form.getBoundingClientRect();
      const tbRect = toolbar.getBoundingClientRect();
          
      // Calcula posição relativa ao form
      let left = rect.left + rect.width / 2 - tbRect.width / 2 - formRect.left;
      let top = rect.top - tbRect.height - 8 - formRect.top + form.scrollTop;
          
      // Limita dentro do form (margem interna de 8px)
      left = Math.max(8, Math.min(left, form.offsetWidth - tbRect.width - 8));
      top = Math.max(8, top);
          
      // Se estiver muito perto do topo, joga pra baixo
      if (top < 8) {
        top = rect.bottom - formRect.top + 8 + form.scrollTop;
      }
      
      // Aplica estilos
      toolbar.style.left = `${left}px`;
      toolbar.style.top = `${top}px`;
      toolbar.classList.add("show");


      updateToolbarButtons();
    };

    const hideToolbar = () => {
      toolbar.classList.remove("show");
      if (headingMenu) headingMenu.classList.remove("show");
      if (sizeMenu) sizeMenu.classList.remove("show");
      currentRange = null;
    };

    const updateToolbarButtons = () => {
      const sel = window.getSelection();
      if (!sel.rangeCount) return;

      const node = sel.getRangeAt(0).commonAncestorContainer;
      const parent = node.nodeType === Node.TEXT_NODE ? node.parentElement : node;

      toolbar.querySelectorAll("button[data-action]").forEach((btn) => {
        const action = btn.dataset.action;
        const selectors = {
          bold: "strong",
          italic: "em",
          strike: "s",
          code: "code",
          quote: "blockquote",
          h1: "h1",
          h2: "h2",
          h3: "h3",
          h4: "h4",
          h5: "h5",
          h6: "h6",
          bulletList: "ul",
          numberedList: "ol"
        };

        btn.classList.toggle("is-active", parent?.closest(selectors[action]) !== null);
      });
    };

    const toggleFormat = (tag) => {
      const sel = window.getSelection();
      if (!sel.rangeCount) return;

      const range = sel.getRangeAt(0);
      const node = sel.anchorNode;
      const parent = node.nodeType === Node.TEXT_NODE ? node.parentElement : node;
      const existing = parent?.closest(tag);

      if (existing && container.contains(existing)) {
        const textNode = document.createTextNode(existing.textContent);
        existing.parentNode.replaceChild(textNode, existing);

        const newRange = document.createRange();
        newRange.selectNodeContents(textNode);
        sel.removeAllRanges();
        sel.addRange(newRange);
        currentRange = newRange.cloneRange();
      } else {
        const wrapper = document.createElement(tag);
        wrapper.appendChild(range.extractContents());
        range.insertNode(wrapper);

        const newRange = document.createRange();
        newRange.selectNodeContents(wrapper);
        sel.removeAllRanges();
        sel.addRange(newRange);
        currentRange = newRange.cloneRange();
      }
    };

    const toggleHeading = (tag) => {
      const sel = window.getSelection();
      if (!sel.rangeCount) return;

      const node = sel.anchorNode;
      const parent = node.nodeType === Node.TEXT_NODE ? node.parentElement : node;
      const existingHeading = parent?.closest("h1, h2, h3, h4, h5, h6");

      let newElement;

      if (existingHeading?.tagName.toLowerCase() === tag) {
        newElement = document.createElement("p");
        newElement.textContent = existingHeading.textContent;
        existingHeading.replaceWith(newElement);
      } else {
        newElement = document.createElement(tag);
        if (existingHeading) {
          newElement.textContent = existingHeading.textContent;
          existingHeading.replaceWith(newElement);
        } else {
          const range = sel.getRangeAt(0);
          newElement.appendChild(range.extractContents());
          range.insertNode(newElement);
        }
      }

      const newRange = document.createRange();
      newRange.selectNodeContents(newElement);
      sel.removeAllRanges();
      sel.addRange(newRange);
      currentRange = newRange.cloneRange();
    };

    const toggleBlockquote = () => {
      const sel = window.getSelection();
      if (!sel.rangeCount) return;

      const node = sel.anchorNode;
      const parent = node.nodeType === Node.TEXT_NODE ? node.parentElement : node;
      const existing = parent?.closest("blockquote");

      let newElement;

      if (existing && container.contains(existing)) {
        newElement = document.createElement("p");
        newElement.textContent = existing.textContent;
        existing.replaceWith(newElement);
      } else {
        const range = sel.getRangeAt(0);
        newElement = document.createElement("blockquote");
        newElement.appendChild(range.extractContents());
        range.insertNode(newElement);
      }

      const newRange = document.createRange();
      newRange.selectNodeContents(newElement);
      sel.removeAllRanges();
      sel.addRange(newRange);
      currentRange = newRange.cloneRange();
    };

    const toggleList = (isOrdered) => {
      const sel = window.getSelection();
      if (!sel.rangeCount) return;

      const node = sel.anchorNode;
      const parent = node.nodeType === Node.TEXT_NODE ? node.parentElement : node;
      const existingList = parent?.closest("ul, ol");
      const listTag = isOrdered ? "ol" : "ul";

      if (existingList) {
        const listItems = Array.from(existingList.querySelectorAll("li"));
        const fragment = document.createDocumentFragment();

        listItems.forEach((li) => {
          const p = document.createElement("p");
          p.textContent = li.textContent;
          fragment.appendChild(p);
        });

        existingList.replaceWith(fragment);
      } else {
        const range = sel.getRangeAt(0);
        const list = document.createElement(listTag);
        const li = document.createElement("li");

        li.appendChild(range.extractContents());
        list.appendChild(li);
        range.insertNode(list);

        const newRange = document.createRange();
        newRange.selectNodeContents(li);
        sel.removeAllRanges();
        sel.addRange(newRange);
        currentRange = newRange.cloneRange();
      }
    };

    const toggleTextSize = (size) => {
      const sel = window.getSelection();
      if (!sel.rangeCount) return;

      const range = sel.getRangeAt(0);
      const node = sel.anchorNode;
      const parent = node.nodeType === Node.TEXT_NODE ? node.parentElement : node;

      const existingSize = parent?.closest(".text-small, .text-large");
      if (existingSize) {
        const textNode = document.createTextNode(existingSize.textContent);
        existingSize.parentNode.replaceChild(textNode, existingSize);

        if (size === "normal") {
          const newRange = document.createRange();
          newRange.selectNodeContents(textNode);
          sel.removeAllRanges();
          sel.addRange(newRange);
          currentRange = newRange.cloneRange();
          return;
        }
      }

      if (size !== "normal") {
        const span = document.createElement("span");
        span.className = size === "small" ? "text-small" : "text-large";

        if (existingSize) {
          span.textContent = parent.textContent;
          parent.replaceWith(span);
        } else {
          span.appendChild(range.extractContents());
          range.insertNode(span);
        }

        const newRange = document.createRange();
        newRange.selectNodeContents(span);
        sel.removeAllRanges();
        sel.addRange(newRange);
        currentRange = newRange.cloneRange();
      }
    };

    // Dropdown de headings
    if (headingBtn) {
      const headingBtnHandler = (e) => {
        e.preventDefault();
        e.stopPropagation();
        if (sizeMenu) sizeMenu.classList.remove("show");
        if (headingMenu) headingMenu.classList.toggle("show");
      };
      addElListener(headingBtn, "mousedown", headingBtnHandler);
    }

    // Dropdown de tamanho
    if (sizeBtn) {
      const sizeBtnHandler = (e) => {
        e.preventDefault();
        e.stopPropagation();
        if (headingMenu) headingMenu.classList.remove("show");
        if (sizeMenu) sizeMenu.classList.toggle("show");
      };
      addElListener(sizeBtn, "mousedown", sizeBtnHandler);
    }

    // Botões da toolbar - delegação
    const handleToolbarClick = (e) => {
      e.preventDefault();
      e.stopPropagation();

      const btn = e.target.closest("button[data-action]");
      if (!btn) return;

      if (currentRange) {
        const sel = window.getSelection();
        sel.removeAllRanges();
        sel.addRange(currentRange);
      }

      const action = btn.dataset.action;

      if (action.startsWith("h")) {
        toggleHeading(action);
        if (headingMenu) headingMenu.classList.remove("show");
      } else if (action.startsWith("size-")) {
        toggleTextSize(action.replace("size-", ""));
        if (sizeMenu) sizeMenu.classList.remove("show");
      } else if (action === "bulletList") {
        toggleList(false);
      } else if (action === "numberedList") {
        toggleList(true);
      } else {
        const tags = { bold: "strong", italic: "em", strike: "s", code: "code", quote: "blockquote" };
        if (tags[action]) (action === "quote" ? toggleBlockquote() : toggleFormat(tags[action]));
      }

      updateMarkdown();

      setTimeout(() => {
        const sel = window.getSelection();
        if (sel.rangeCount) currentRange = sel.getRangeAt(0).cloneRange();
        updateToolbarButtons();
      }, 0);
    };
    if (toolbar) addElListener(toolbar, "mousedown", handleToolbarClick);

    // Eventos globais (selectionchange, mousedown, click)
    const selectionChangeHandler = () => {
      if (document.activeElement === container || container.contains(document.activeElement)) {
        const sel = window.getSelection();
        if (!sel.isCollapsed && container.contains(sel.anchorNode)) showToolbar();
        else hideToolbar();
      }
    };
    addDocListener("selectionchange", selectionChangeHandler);

    const docMousedownHandler = (e) => {
      if (!container.contains(e.target) && !toolbar.contains(e.target)) hideToolbar();
    };
    addDocListener("mousedown", docMousedownHandler);

    const docClickHandler = (e) => {
      if (headingBtn && !headingBtn.contains(e.target) && headingMenu) headingMenu.classList.remove("show");
      if (sizeBtn && !sizeBtn.contains(e.target) && sizeMenu) sizeMenu.classList.remove("show");
    };
    addDocListener("click", docClickHandler);

    // Suporte a Enter em listas
    const handleKeydown = (e) => {
      if (e.key === "Enter") {
        const sel = window.getSelection();
        if (!sel.rangeCount) return;

        const node = sel.anchorNode;
        const parent = node.nodeType === Node.TEXT_NODE ? node.parentElement : node;
        const listItem = parent?.closest("li");

        if (listItem) {
          e.preventDefault();

          if (!listItem.textContent.trim()) {
            const list = listItem.closest("ul, ol");
            const p = document.createElement("p");
            p.innerHTML = "<br>";

            if (listItem.nextSibling) {
              list.insertBefore(p, listItem);
            } else {
              list.parentNode.insertBefore(p, list.nextSibling);
            }

            listItem.remove();

            if (!list.children.length) list.remove();

            selectNode(p);
          } else {
            const newLi = document.createElement("li");
            newLi.innerHTML = "<br>";
            listItem.parentNode.insertBefore(newLi, listItem.nextSibling);
            selectNode(newLi);
          }

          updateMarkdown();
        }
      }
    };
    addElListener(container, "keydown", handleKeydown);
  }
}
