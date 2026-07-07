"use client";

import type { Components } from "react-markdown";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";
import rehypeSanitize, { defaultSchema } from "rehype-sanitize";

const sanitizeSchema = {
  ...defaultSchema,
  tagNames: defaultSchema.tagNames?.filter((tag) => tag !== "img"),
};

const SAFE_LINK_PROTOCOL = /^(https?:|mailto:)/i;

function isSafeHref(href: string | undefined): href is string {
  return typeof href === "string" && SAFE_LINK_PROTOCOL.test(href);
}

const markdownComponents: Components = {
  a: ({ href, children }) => {
    if (!isSafeHref(href)) {
      return <span>{children}</span>;
    }

    return (
      <a href={href} target="_blank" rel="noopener noreferrer">
        {children}
      </a>
    );
  },
  img: () => null,
  p: ({ children }) => <p className="whitespace-pre-wrap">{children}</p>,
};

type MarkdownTextProps = {
  children: string;
  className?: string;
};

export function MarkdownText({ children, className = "" }: MarkdownTextProps) {
  return (
    <div
      className={`space-y-1 [&_a]:text-amber-700 [&_a]:underline dark:[&_a]:text-amber-400 [&_del]:line-through [&_ol]:my-1 [&_ol]:list-decimal [&_ol]:pl-5 [&_strong]:font-semibold [&_table]:my-2 [&_table]:w-full [&_table]:overflow-x-auto [&_table]:text-sm [&_td]:border [&_td]:border-zinc-200 [&_td]:px-2 [&_td]:py-1 dark:[&_td]:border-zinc-700 [&_th]:border [&_th]:border-zinc-200 [&_th]:px-2 [&_th]:py-1 dark:[&_th]:border-zinc-700 [&_ul]:my-1 [&_ul]:list-disc [&_ul]:pl-5 ${className}`}
    >
      <ReactMarkdown
        remarkPlugins={[remarkGfm]}
        rehypePlugins={[[rehypeSanitize, sanitizeSchema]]}
        components={markdownComponents}
      >
        {children}
      </ReactMarkdown>
    </div>
  );
}
