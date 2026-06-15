// Asset module declarations so `require("...ttf")` type-checks under
// `tsc --noEmit` even before Expo regenerates expo-env.d.ts.
declare module "*.ttf" {
  const asset: number;
  export default asset;
}
