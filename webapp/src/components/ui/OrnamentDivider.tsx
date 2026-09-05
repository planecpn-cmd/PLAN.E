export function OrnamentDivider({ className = "" }: { className?: string }) {
  return (
    <div className={`ornament-divider ${className}`}>
      <span className="ornament-divider__diamond" />
    </div>
  );
}
