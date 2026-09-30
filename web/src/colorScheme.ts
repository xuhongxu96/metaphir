// The color scheme: the system's, or light or dark as chosen, remembered in
// localStorage and applied as <html data-theme>.

import { useEffect, useState, useSyncExternalStore } from "react";

export type SchemePreference = "system" | "light" | "dark";

const STORAGE_KEY = "metaphir-color-scheme";
const systemDark = window.matchMedia("(prefers-color-scheme: dark)");

function readPreference(): SchemePreference {
  try {
    const stored = localStorage.getItem(STORAGE_KEY);
    return stored === "light" || stored === "dark" ? stored : "system";
  } catch {
    return "system";
  }
}

let preference = readPreference();
const listeners = new Set<() => void>();

function apply(chosen: SchemePreference): void {
  if (chosen === "system") delete document.documentElement.dataset.theme;
  else document.documentElement.dataset.theme = chosen;
}
apply(preference);

function setPreference(chosen: SchemePreference): void {
  preference = chosen;
  try {
    if (chosen === "system") localStorage.removeItem(STORAGE_KEY);
    else localStorage.setItem(STORAGE_KEY, chosen);
  } catch {
    // Storage may be unavailable, as in private windows.
  }
  apply(chosen);
  for (const listener of listeners) listener();
}

/** The chosen preference, a setter, and whether the page is dark. */
export function useColorScheme(): {
  preference: SchemePreference;
  setPreference: (chosen: SchemePreference) => void;
  dark: boolean;
} {
  const chosen = useSyncExternalStore(
    (listener) => {
      listeners.add(listener);
      return () => listeners.delete(listener);
    },
    () => preference,
  );
  const [system, setSystem] = useState(systemDark.matches);
  useEffect(() => {
    const update = () => setSystem(systemDark.matches);
    systemDark.addEventListener("change", update);
    return () => systemDark.removeEventListener("change", update);
  }, []);
  return {
    preference: chosen,
    setPreference,
    dark: chosen === "dark" || (chosen === "system" && system),
  };
}
