// Matches lib/widgets/plan_e_logo.dart exactly: positioned P / L / [mountain
// glyph] / N / E, the glyph a real asset (public/brand/mountain-a.png, copied
// from assets/images/plan_e_mountain_a.png) tinted via CSS mask-image the
// same way Dart tints it with BlendMode.srcIn.
export function Logo({ size = 26, color = "var(--color-forest)" }: { size?: number; color?: string }) {
  const width = size * 6.6;
  const height = size * 1.2;
  const letterStyle: React.CSSProperties = {
    position: "absolute",
    top: 0,
    width: size,
    height,
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    fontFamily: "var(--font-display), serif",
    fontSize: size,
    fontWeight: 700,
    lineHeight: 1,
    color,
  };

  const letter = (value: string, center: number) => (
    <span style={{ ...letterStyle, left: width * center - size * 0.5 }}>{value}</span>
  );

  return (
    <span
      role="img"
      aria-label="PLAN E logo"
      style={{ position: "relative", display: "inline-block", width, height }}
    >
      {letter("P", 0.076)}
      {letter("L", 0.254)}
      <span
        aria-hidden="true"
        style={{
          position: "absolute",
          left: width * 0.482 - size * 0.775,
          top: 0,
          width: size * 1.55,
          height,
          backgroundColor: color,
          WebkitMaskImage: "url(/brand/mountain-a.png)",
          maskImage: "url(/brand/mountain-a.png)",
          WebkitMaskRepeat: "no-repeat",
          maskRepeat: "no-repeat",
          WebkitMaskSize: "contain",
          maskSize: "contain",
          WebkitMaskPosition: "center",
          maskPosition: "center",
        }}
      />
      {letter("N", 0.73)}
      {letter("E", 0.924)}
    </span>
  );
}
