const baseUrl = new URL(process.env.CONSISTIFIT_URL || 'https://bhrcs.github.io/ConsistiFit/');

async function fetchWithRetry(relative, attempts = 3) {
  const url = new URL(relative, baseUrl);
  let lastError;
  for (let attempt = 1; attempt <= attempts; attempt++) {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 15000);
    try {
      const response = await fetch(url, { redirect: 'follow', signal: controller.signal, headers: { 'cache-control': 'no-cache' } });
      clearTimeout(timeout);
      if (!response.ok) throw new Error(`${response.status} ${response.statusText}`);
      return { url, response, text: await response.text() };
    } catch (error) {
      clearTimeout(timeout);
      lastError = error;
      if (attempt < attempts) await new Promise(resolve => setTimeout(resolve, attempt * 1500));
    }
  }
  throw new Error(`${url}: ${lastError?.message || lastError}`);
}

(async () => {
  const home = await fetchWithRetry('');
  if (!/ConsistiFit/i.test(home.text)) throw new Error('Production HTML does not contain ConsistiFit');

  const manifestResult = await fetchWithRetry('manifest.webmanifest');
  const manifest = JSON.parse(manifestResult.text);
  if (manifest.name !== 'ConsistiFit') throw new Error('Production manifest is invalid');

  const sw = await fetchWithRetry('service-worker.js');
  if (!sw.text.includes('consistifit-playable-')) throw new Error('Production service worker cache marker is missing');
  if (sw.text.includes('__BUILD_ID__')) throw new Error('Production service worker was deployed without a stamped build id');

  const build = await fetchWithRetry('build-info.json');
  const buildInfo = JSON.parse(build.text);
  if (!buildInfo.commit || !buildInfo.buildId) throw new Error('Production build-info.json is incomplete');
  if (!sw.text.includes(buildInfo.buildId)) throw new Error('Production build-info does not match the active service-worker cache');

  const localRefs = new Set();
  for (const match of home.text.matchAll(/(?:src|href)=["']([^"']+)["']/g)) {
    const value = match[1].split('#')[0];
    if (!value || /^(?:data:|mailto:|tel:|#)/i.test(value)) continue;
    const url = new URL(value, baseUrl);
    if (url.origin === baseUrl.origin && url.pathname.startsWith(baseUrl.pathname)) localRefs.add(url.href);
  }
  for (const url of localRefs) {
    const relative = url.slice(baseUrl.href.length);
    await fetchWithRetry(relative, 2);
  }

  console.log(`Production healthy: ${baseUrl.href}`);
  console.log(`Live build: ${buildInfo.buildId} (${String(buildInfo.commit).slice(0, 12)})`);
  console.log(`Verified ${localRefs.size} page assets plus manifest, service worker, and build metadata.`);
})().catch(error => {
  console.error(`ConsistiFit production health check failed: ${error.message}`);
  process.exit(1);
});
