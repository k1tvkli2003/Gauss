declare module "react-native-mathjax-svg" {
  import type { ComponentType, ReactNode } from "react";

  interface MathJaxSvgProps {
    /** TeX/LaTeX source (no $ delimiters). */
    children?: ReactNode;
    /** Pixel font size for the rendered glyphs. */
    fontSize?: number;
    /** Glyph color. */
    color?: string;
    /** Cache parsed glyph paths between renders. */
    fontCache?: boolean;
    style?: object;
  }

  const MathJaxSvg: ComponentType<MathJaxSvgProps>;
  export default MathJaxSvg;
}
