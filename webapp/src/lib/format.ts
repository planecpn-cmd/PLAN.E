export function formatNpr(paisa: number): string {
  return `Rs. ${(paisa / 100).toLocaleString("en-IN")}`;
}
