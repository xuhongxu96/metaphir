// The site's corpus list: config.json names one or more published corpora.

export interface CorpusConfig {
  id: string;
  label: string;
  description?: string;
  /** The build root: the URL under which manifest.json and the data live. */
  data: string;
}

export interface SiteConfig {
  default: string;
  corpora: CorpusConfig[];
}

const ID = /^[A-Za-z0-9._-]+$/;

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

/**
 * Parses config.json. A legacy `{"data": "..."}` is one corpus named
 * "original"; the list form is preferred.
 */
export function parseConfig(raw: unknown): SiteConfig {
  if (!isRecord(raw)) throw new Error("config.json is not an object");
  if (Array.isArray(raw.corpora)) {
    const corpora: CorpusConfig[] = [];
    const seen = new Set<string>();
    for (const item of raw.corpora) {
      if (!isRecord(item)) throw new Error("config.json: a corpus is not an object");
      const { id, label, description, data } = item;
      if (typeof id !== "string" || !ID.test(id))
        throw new Error(`config.json: invalid corpus id ${JSON.stringify(id)}`);
      if (seen.has(id)) throw new Error(`config.json: duplicate corpus id ${id}`);
      if (typeof data !== "string" || data === "")
        throw new Error(`config.json: corpus ${id} has no data URL`);
      seen.add(id);
      corpora.push({
        id,
        label: typeof label === "string" && label !== "" ? label : id,
        ...(typeof description === "string" ? { description } : {}),
        data,
      });
    }
    if (corpora.length === 0) throw new Error("config.json: no corpora");
    const wanted = typeof raw.default === "string" ? raw.default : "";
    const fallback = corpora.some((c) => c.id === wanted) ? wanted : corpora[0].id;
    return { default: fallback, corpora };
  }

  const data = raw.data;
  if (typeof data !== "string" || data === "")
    throw new Error("config.json: set corpora or data");
  if (data.includes("OWNER"))
    throw new Error("No corpus is configured: set corpora or data in config.json.");
  return {
    default: "original",
    corpora: [{ id: "original", label: "Corpus", data }],
  };
}

export async function loadConfig(): Promise<SiteConfig> {
  const response = await fetch("config.json", { cache: "no-cache" });
  return parseConfig(await response.json());
}

export function findCorpus(
  config: SiteConfig,
  id: string | null,
): CorpusConfig {
  return (
    config.corpora.find((c) => c.id === id) ??
    config.corpora.find((c) => c.id === config.default) ??
    config.corpora[0]
  );
}
