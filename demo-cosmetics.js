(() => {
  function owned(code){return (state.inventory?.[code]||0)>0||(state.purchased||[]).includes(code)}
  function renderFlair(){
    const screen=document.getElementById('screen-profile');if(!screen)return;
    const cosmetics=state.depth?.cosmetics||{};
    const headline=screen.querySelector(':scope > .headline');
    if(headline&&!screen.querySelector('.cf-profile-flair')&&(cosmetics.title==='title_consistent'||cosmetics.badge==='badge_founder')){
      headline.insertAdjacentHTML('afterend',`<div class="cf-profile-flair">${cosmetics.badge==='badge_founder'?'<span class="cf-profile-badge">◇ CONSISTENCY</span>':''}${cosmetics.title==='title_consistent'?'<span class="cf-profile-title">“Consistent”</span>':''}</div>`);
    }
    const list=screen.querySelector('.cf-cosmetics');
    if(list&&!list.querySelector('[data-finish-effect]')){
      const active=cosmetics.finish==='finish_burst';
      list.insertAdjacentHTML('beforeend',`<button class="sheet-option" data-finish-effect onclick="cfSetCosmetic('finish',${active?'null':"'finish_burst'"})"><span><b>Finish Burst effect</b><small class="sub">${owned('finish_burst')?(active?'Equipped · tap to remove':'Owned · tap to equip'):'Buy it in the Coin Shop'}</small></span><span>${active?'✓':'›'}</span></button>`);
    }
  }
  const priorRenderAll=window.renderAll;
  window.renderAll=function renderAllWithCosmeticFlair(){priorRenderAll();renderFlair()};
  renderFlair();
})();
