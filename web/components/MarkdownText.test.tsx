import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import { MarkdownText } from "@/components/MarkdownText";

describe("MarkdownText", () => {
  it("renders bold text", () => {
    render(<MarkdownText>**$20 sando + fries**</MarkdownText>);

    const strong = screen.getByText("$20 sando + fries");
    expect(strong.tagName).toBe("STRONG");
  });

  it("renders list items", () => {
    render(<MarkdownText>{"- Sparkling Wine\n- Tap Beer"}</MarkdownText>);

    expect(screen.getByRole("list")).toBeInTheDocument();
    expect(screen.getByText("Sparkling Wine")).toBeInTheDocument();
    expect(screen.getByText("Tap Beer")).toBeInTheDocument();
  });

  it("renders safe links with noopener noreferrer", () => {
    render(<MarkdownText>[menu](https://example.com/menu)</MarkdownText>);

    const link = screen.getByRole("link", { name: "menu" });
    expect(link).toHaveAttribute("href", "https://example.com/menu");
    expect(link).toHaveAttribute("target", "_blank");
    expect(link).toHaveAttribute("rel", "noopener noreferrer");
  });

  it("rejects javascript links", () => {
    render(<MarkdownText>[click me](javascript:alert(1))</MarkdownText>);

    expect(screen.queryByRole("link")).not.toBeInTheDocument();
    expect(screen.getByText("click me")).toBeInTheDocument();
  });

  it("does not render raw HTML script tags", () => {
    const { container } = render(
      <MarkdownText>{"<script>alert(1)</script>"}</MarkdownText>,
    );

    expect(container.querySelector("script")).toBeNull();
    expect(container.textContent).not.toContain("alert(1)");
  });

  it("does not render markdown images", () => {
    const { container } = render(
      <MarkdownText>![](https://tracker.example/pixel.gif)</MarkdownText>,
    );

    expect(container.querySelector("img")).toBeNull();
  });

  it("renders plain multiline text without markdown", () => {
    render(<MarkdownText>{"$8 wines\n$8 schooners"}</MarkdownText>);

    expect(screen.getByText(/\$8 wines/)).toBeInTheDocument();
    expect(screen.getByText(/\$8 schooners/)).toBeInTheDocument();
  });
});
