import React, { useMemo } from "react";
import { ScrollView, Text, View, type TextStyle } from "react-native";
import MathJaxSvg from "react-native-mathjax-svg";
import { colors } from "@/theme/colors";

interface Props {
  content: string;
  fontSize?: number;
  color?: string;
}

/**
 * Renders markdown-lite + LaTeX **fully natively** — no WebView, no HTML.
 * Math is drawn as SVG glyphs (MathJax → react-native-svg); text, lists, bold
 * and code are real React Native primitives, RTL/Persian aware.
 *
 * Inline math: $...$   ·   Block math: $$...$$
 */
export function MathText({ content, fontSize = 17, color = colors.text }: Props) {
  const blocks = useMemo(() => splitDisplayMath(content), [content]);

  return (
    <View style={{ paddingVertical: 2, paddingHorizontal: 4 }}>
      {blocks.map((b, i) =>
        b.type === "display" ? (
          <DisplayMath key={i} tex={b.value} fontSize={fontSize} color={color} />
        ) : (
          <TextBlock key={i} text={b.value} fontSize={fontSize} color={color} />
        ),
      )}
    </View>
  );
}

/* ------------------------------------------------------------------ */
/* Display ($$ … $$) math — centred, horizontally scrollable if wide. */
/* ------------------------------------------------------------------ */

function DisplayMath({
  tex,
  fontSize,
  color,
}: {
  tex: string;
  fontSize: number;
  color: string;
}) {
  return (
    <ScrollView
      horizontal
      showsHorizontalScrollIndicator={false}
      contentContainerStyle={{ flexGrow: 1, justifyContent: "center" }}
      style={{ marginVertical: 8 }}
    >
      <MathJaxSvg fontSize={Math.round(fontSize * 1.18)} color={color} fontCache>
        {tex}
      </MathJaxSvg>
    </ScrollView>
  );
}

/* ------------------------------------------------------------------ */
/* Text block — markdown-lite lines with inline $…$ math.             */
/* ------------------------------------------------------------------ */

function TextBlock({
  text,
  fontSize,
  color,
}: {
  text: string;
  fontSize: number;
  color: string;
}) {
  const lines = text.split("\n");
  const out: React.ReactNode[] = [];
  let listBuffer: string[] = [];

  const flushList = (k: string) => {
    if (listBuffer.length === 0) return;
    const items = listBuffer;
    listBuffer = [];
    out.push(
      <View key={k} style={{ marginVertical: 2 }}>
        {items.map((it, i) => (
          <View
            key={i}
            style={{ flexDirection: "row-reverse", alignItems: "flex-start", marginBottom: 4 }}
          >
            <Text style={{ color: colors.neonBlue, fontSize, lineHeight: fontSize * 1.7 }}>
              {"•  "}
            </Text>
            <View style={{ flex: 1 }}>
              <Line content={it} fontSize={fontSize} color={color} />
            </View>
          </View>
        ))}
      </View>,
    );
  };

  lines.forEach((raw, idx) => {
    const t = raw.trim();
    const listMatch = /^[-*]\s+(.*)$/.exec(t);
    if (listMatch) {
      listBuffer.push(listMatch[1]);
      return;
    }
    flushList(`list-${idx}`);

    if (t === "") {
      out.push(<View key={`sp-${idx}`} style={{ height: fontSize * 0.5 }} />);
      return;
    }
    if (/^---+$/.test(t)) {
      out.push(
        <View
          key={`hr-${idx}`}
          style={{ height: 1, backgroundColor: colors.border, marginVertical: 10 }}
        />,
      );
      return;
    }
    out.push(<Line key={`l-${idx}`} content={raw} fontSize={fontSize} color={color} />);
  });

  flushList("list-tail");
  return <>{out}</>;
}

/* ------------------------------------------------------------------ */
/* A single line: inline $…$ math + **bold** + `code`.                */
/* ------------------------------------------------------------------ */

function Line({
  content,
  fontSize,
  color,
}: {
  content: string;
  fontSize: number;
  color: string;
}) {
  const parts = splitInlineMath(content);

  // Pure text line → one <Text> for proper Persian shaping & wrapping.
  if (parts.every((p) => p.type === "text")) {
    return (
      <Text
        style={{
          color,
          fontSize,
          lineHeight: fontSize * 1.7,
          writingDirection: "rtl",
          textAlign: "right",
        }}
      >
        {parts.map((p, i) => renderInlineMarkdown(p.value, i, fontSize, color))}
      </Text>
    );
  }

  // Pure math line → render the formula on its own row.
  const mathOnly =
    parts.length === 1 && parts[0].type === "math"
      ? parts[0]
      : parts.filter((p) => p.type === "text").every((p) => p.value.trim() === "") &&
          parts.filter((p) => p.type === "math").length === 1
        ? parts.find((p) => p.type === "math")
        : null;
  if (mathOnly) {
    return (
      <View style={{ alignItems: "flex-end", marginVertical: 4 }}>
        <MathJaxSvg fontSize={fontSize} color={color} fontCache>
          {mathOnly.value}
        </MathJaxSvg>
      </View>
    );
  }

  // Mixed text + inline math → wrap word-by-word so the line can reflow.
  const items: React.ReactNode[] = [];
  parts.forEach((p, pi) => {
    if (p.type === "math") {
      items.push(
        <View key={`m-${pi}`} style={{ marginHorizontal: 2, justifyContent: "center" }}>
          <MathJaxSvg fontSize={fontSize} color={color} fontCache>
            {p.value}
          </MathJaxSvg>
        </View>,
      );
    } else {
      p.value.split(/(\s+)/).forEach((word, wi) => {
        if (word === "") return;
        if (/^\s+$/.test(word)) {
          items.push(<Text key={`s-${pi}-${wi}`}>{" "}</Text>);
          return;
        }
        items.push(
          <Text
            key={`w-${pi}-${wi}`}
            style={{ color, fontSize, lineHeight: fontSize * 1.7, writingDirection: "rtl" }}
          >
            {renderInlineMarkdown(word, 0, fontSize, color)}
          </Text>,
        );
      });
    }
  });

  return (
    <View
      style={{
        flexDirection: "row-reverse",
        flexWrap: "wrap",
        alignItems: "center",
        justifyContent: "flex-start",
      }}
    >
      {items}
    </View>
  );
}

/* ------------------------------------------------------------------ */
/* Inline markdown: **bold** and `code` inside a <Text> run.          */
/* ------------------------------------------------------------------ */

function renderInlineMarkdown(
  src: string,
  keyBase: number,
  fontSize: number,
  color: string,
): React.ReactNode {
  const tokens = src.split(/(\*\*[^*]+\*\*|`[^`]+`)/g).filter((s) => s !== "");
  if (tokens.length <= 1 && !/^\*\*|^`/.test(src)) return src;

  return tokens.map((tok, i) => {
    const key = `${keyBase}-${i}`;
    if (/^\*\*[^*]+\*\*$/.test(tok)) {
      return (
        <Text key={key} style={{ color: colors.neonBlue, fontWeight: "700" }}>
          {tok.slice(2, -2)}
        </Text>
      );
    }
    if (/^`[^`]+`$/.test(tok)) {
      return (
        <Text
          key={key}
          style={{
            color: colors.neonAmber,
            backgroundColor: colors.raised,
            fontSize: fontSize * 0.92,
          } as TextStyle}
        >
          {` ${tok.slice(1, -1)} `}
        </Text>
      );
    }
    return (
      <Text key={key} style={{ color }}>
        {tok}
      </Text>
    );
  });
}

/* ------------------------------------------------------------------ */
/* Parsing helpers.                                                    */
/* ------------------------------------------------------------------ */

type Block = { type: "text" | "display"; value: string };

function splitDisplayMath(src: string): Block[] {
  const out: Block[] = [];
  const re = /\$\$([\s\S]+?)\$\$/g;
  let last = 0;
  let m: RegExpExecArray | null;
  while ((m = re.exec(src)) !== null) {
    if (m.index > last) out.push({ type: "text", value: src.slice(last, m.index) });
    out.push({ type: "display", value: m[1].trim() });
    last = re.lastIndex;
  }
  if (last < src.length) out.push({ type: "text", value: src.slice(last) });
  return out.length > 0 ? out : [{ type: "text", value: src }];
}

type InlinePart = { type: "text" | "math"; value: string };

function splitInlineMath(line: string): InlinePart[] {
  const out: InlinePart[] = [];
  const re = /\$([^$]+?)\$/g;
  let last = 0;
  let m: RegExpExecArray | null;
  while ((m = re.exec(line)) !== null) {
    if (m.index > last) out.push({ type: "text", value: line.slice(last, m.index) });
    out.push({ type: "math", value: m[1].trim() });
    last = re.lastIndex;
  }
  if (last < line.length) out.push({ type: "text", value: line.slice(last) });
  return out.length > 0 ? out : [{ type: "text", value: line }];
}
