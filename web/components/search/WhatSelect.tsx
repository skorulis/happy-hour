"use client";

import {
  filterSuggestions,
  findProductByName,
  getInitialSuggestions,
  type Product,
} from "@data/products";
import { X } from "lucide-react";
import { useEffect, useMemo, useRef, useState } from "react";
import {
  isRegisteredProductIcon,
  ProductMapIcon,
} from "@/lib/search/ProductMapIcon";

type WhatSelectPanelProps = {
  tokens: string[];
  onChange: (tokens: string[]) => void;
  onClose: () => void;
  open: boolean;
};

function tokenSet(tokens: string[]): Set<string> {
  return new Set(tokens.map((token) => token.toLowerCase()));
}

function hasToken(tokens: string[], value: string): boolean {
  const lower = value.toLowerCase();
  return tokens.some((token) => token.toLowerCase() === lower);
}

function SuggestionIcon({ product }: { product: Product }) {
  if (!product.icon || !isRegisteredProductIcon(product.icon)) {
    return (
      <span
        aria-hidden
        className="inline-flex h-7 w-7 shrink-0 items-center justify-center rounded-lg bg-zinc-100 dark:bg-zinc-800"
      />
    );
  }

  return (
    <span className="inline-flex h-7 w-7 shrink-0 items-center justify-center rounded-lg bg-amber-50 text-amber-700 dark:bg-amber-950/40 dark:text-amber-400">
      <ProductMapIcon name={product.icon} size={14} />
    </span>
  );
}

function TokenIcon({ token }: { token: string }) {
  const icon = findProductByName(token)?.icon;
  if (!icon || !isRegisteredProductIcon(icon)) {
    return null;
  }

  return (
    <ProductMapIcon
      name={icon}
      size={12}
      className="shrink-0 text-amber-700 dark:text-amber-400"
    />
  );
}

export function WhatSelectPanel({
  tokens,
  onChange,
  onClose,
  open,
}: WhatSelectPanelProps) {
  const [input, setInput] = useState("");
  const [highlightIndex, setHighlightIndex] = useState(0);
  const inputRef = useRef<HTMLInputElement>(null);

  const exclude = useMemo(() => tokenSet(tokens), [tokens]);
  const suggestions = useMemo(() => {
    if (!open) {
      return [];
    }
    return input.trim()
      ? filterSuggestions(input, exclude)
      : getInitialSuggestions(exclude);
  }, [open, input, exclude]);
  const activeHighlightIndex =
    suggestions.length === 0
      ? 0
      : Math.min(highlightIndex, suggestions.length - 1);

  useEffect(() => {
    if (!open) {
      return;
    }

    inputRef.current?.focus();
  }, [open]);

  function addToken(value: string) {
    const trimmed = value.trim();
    if (!trimmed || hasToken(tokens, trimmed)) {
      setInput("");
      return;
    }
    onChange([...tokens, trimmed]);
    setInput("");
    setHighlightIndex(0);
    onClose();
  }

  function removeToken(index: number) {
    onChange(tokens.filter((_, tokenIndex) => tokenIndex !== index));
    inputRef.current?.focus();
  }

  function removeLastToken() {
    if (tokens.length === 0) {
      return;
    }
    onChange(tokens.slice(0, -1));
  }

  function selectSuggestion(product: Product) {
    addToken(product.name);
  }

  function handleInputKeyDown(event: React.KeyboardEvent<HTMLInputElement>) {
    if (event.key === "ArrowDown") {
      event.preventDefault();
      setHighlightIndex((current) =>
        suggestions.length === 0
          ? 0
          : Math.min(current + 1, suggestions.length - 1),
      );
      return;
    }

    if (event.key === "ArrowUp") {
      event.preventDefault();
      setHighlightIndex((current) => Math.max(current - 1, 0));
      return;
    }

    if (event.key === "Enter" || event.key === "Tab") {
      if (suggestions.length > 0 && event.key === "Enter") {
        event.preventDefault();
        selectSuggestion(suggestions[activeHighlightIndex]);
        return;
      }
      if (input.trim()) {
        event.preventDefault();
        addToken(input);
      }
      return;
    }

    if (event.key === "Backspace" && !input && tokens.length > 0) {
      event.preventDefault();
      removeLastToken();
      return;
    }

    if (event.key === "Escape") {
      event.preventDefault();
      onClose();
    }
  }

  const listboxId = "what-select-listbox";

  return (
    <div className="w-80 max-w-[calc(100vw-3rem)] rounded-xl border border-zinc-200 bg-white p-3 shadow-lg dark:border-zinc-700 dark:bg-zinc-900">
      <div className="flex min-h-[2.25rem] w-full flex-wrap items-center gap-1.5 rounded-lg border border-zinc-300 bg-white px-3 py-1.5 dark:border-zinc-600 dark:bg-zinc-950">
        {tokens.map((token, index) => (
          <span
            key={`${token}-${index}`}
            className="inline-flex max-w-full items-center gap-1 rounded-full bg-amber-100 px-2.5 py-0.5 text-xs font-medium text-amber-800 dark:bg-amber-950/50 dark:text-amber-300"
          >
            <TokenIcon token={token} />
            <span className="truncate">{token}</span>
            <button
              type="button"
              onClick={() => removeToken(index)}
              className="rounded p-0.5 text-amber-600 hover:bg-amber-200/80 hover:text-amber-900 dark:text-amber-400 dark:hover:bg-amber-900/60 dark:hover:text-amber-200"
              aria-label={`Remove ${token}`}
            >
              <X className="h-3 w-3" />
            </button>
          </span>
        ))}
        <input
          ref={inputRef}
          type="text"
          value={input}
          role="combobox"
          aria-expanded={open}
          aria-autocomplete="list"
          aria-controls={listboxId}
          aria-activedescendant={
            suggestions.length > 0
              ? `what-option-${activeHighlightIndex}`
              : undefined
          }
          onChange={(event) => {
            setInput(event.target.value);
            setHighlightIndex(0);
          }}
          onKeyDown={handleInputKeyDown}
          placeholder={tokens.length === 0 ? "steak, happy hour, pizza..." : ""}
          className="min-w-[6ch] flex-1 border-0 bg-transparent text-sm font-medium text-zinc-900 outline-none placeholder:text-zinc-400 dark:text-zinc-50 dark:placeholder:text-zinc-500"
        />
      </div>

      <div
        id={listboxId}
        role="listbox"
        className="mt-2 max-h-48 overflow-y-auto rounded-lg"
      >
        {suggestions.length === 0 ? (
          <p className="px-2 py-2 text-sm text-zinc-500">
            {input.trim() ? "No matches." : "No suggestions."}
          </p>
        ) : (
          suggestions.map((product, index) => (
            <button
              key={product.name}
              id={`what-option-${index}`}
              type="button"
              role="option"
              aria-selected={index === activeHighlightIndex}
              onMouseEnter={() => setHighlightIndex(index)}
              onClick={() => selectSuggestion(product)}
              className={`flex w-full items-center gap-2.5 rounded-lg px-2 py-2 text-left text-sm ${
                index === activeHighlightIndex
                  ? "bg-amber-50 font-medium text-amber-700 dark:bg-amber-950/40 dark:text-amber-400"
                  : "text-zinc-800 hover:bg-zinc-100 dark:text-zinc-200 dark:hover:bg-zinc-800"
              }`}
            >
              <SuggestionIcon product={product} />
              <span className="min-w-0 flex-1">{product.name}</span>
            </button>
          ))
        )}
      </div>
    </div>
  );
}
