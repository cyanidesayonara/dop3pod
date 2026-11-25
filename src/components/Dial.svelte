<script lang="ts">
  let { label, options, value = $bindable(), detail, disabled }: {
    label: string; options: { id: string; name: string }[]; value: string; detail: string; disabled: boolean;
  } = $props();
  const at = $derived(Math.max(0, options.findIndex((o) => o.id === value)));
  const turn = (n: number) => (value = options[(at + n + options.length) % options.length].id);
</script>

<div class="dial" role="group" aria-label={label}>
  <button class="square" onclick={() => turn(-1)} aria-label="Previous {label.toLowerCase()}" {disabled}>
    <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M6 15l6-6 6 6" /></svg>
  </button>
  <div class="circle" aria-live="polite">
    <strong>{options[at]?.name ?? '…'}</strong>
    <span>{detail}</span>
  </div>
  <button class="square" onclick={() => turn(1)} aria-label="Next {label.toLowerCase()}" {disabled}>
    <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M6 9l6 6 6-6" /></svg>
  </button>
</div>
