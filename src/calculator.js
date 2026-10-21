// Simple functions jinke tests CI mein chalenge
export function add(a, b) {
  return a + b;
}

export function subtract(a, b) {
  return a - b;
}

export function divide(a, b) {
  if (b === 0) throw new Error("Zero se divide nahi kar sakte");
  return a / b;
}
