<script lang="ts">
  let { title, src, size }: { title: string; src: string; size: number } = $props();
  let brokenSrc = $state('');
  const letter = $derived(/[\p{L}\p{N}]/u.exec(title.replace(/^the /i, ''))?.[0] ?? '?');
</script>

<!-- Decorative: the title is always next to it. -->
<span class="cover" style:width="{size}px" style:height="{size}px" aria-hidden="true">
  <span>{letter}</span>
  {#if src && brokenSrc !== src}
    <img {src} alt="" width={size} height={size} loading="lazy" decoding="async" referrerpolicy="no-referrer" onerror={() => (brokenSrc = src)} />
  {/if}
</span>
