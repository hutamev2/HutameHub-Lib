(() => {
  const main = document.querySelector('.content');
  const pages = [...main.querySelectorAll(':scope > section')];
  const links = [...document.querySelectorAll('.sb-links a[href^="#"]')];
  const sidebar = document.querySelector('.sidebar');
  const menu = document.querySelector('.menu-toggle');
  const toc = document.querySelector('.page-toc');
  const pagination = document.querySelector('.page-pagination');
  const title = page => page.querySelector('h1,.method-title,h2')?.textContent.trim() || page.id;
  document.querySelectorAll('.params-table,.guide table').forEach(table => {
    const wrapper = document.createElement('div'); wrapper.className = 'table-scroll';
    wrapper.tabIndex = 0; wrapper.setAttribute('aria-label', 'Scrollable parameter table');
    table.before(wrapper); wrapper.append(table);
  });
  function closeMenu() { sidebar.classList.remove('open'); menu.setAttribute('aria-expanded','false'); }
  menu.addEventListener('click', () => {
    const open = sidebar.classList.toggle('open'); menu.setAttribute('aria-expanded', String(open));
    if (open) document.getElementById('sbSearch').focus();
  });
  document.addEventListener('keydown', event => {
    if (event.key === 'Escape') { closeMenu(); menu.focus(); }
    if ((event.ctrlKey || event.metaKey) && event.key === 'k') {
      event.preventDefault(); sidebar.classList.add('open'); menu.setAttribute('aria-expanded','true'); document.getElementById('sbSearch').focus();
    }
  });
  function render() {
    let hash; try { hash = decodeURIComponent(location.hash.slice(1)); } catch { hash = ''; }
    const target = document.getElementById(hash);
    const page = pages.find(p => p === target || p.contains(target)) || pages[0];
    pages.forEach(p => p.hidden = p !== page);
    links.forEach(link => {
      const active = link.hash === '#' + page.id;
      link.classList.toggle('active', active);
      if (active) link.setAttribute('aria-current','page'); else link.removeAttribute('aria-current');
    });
    document.title = title(page) + ' · HutameHub Docs';
    toc.replaceChildren(); const label = document.createElement('strong'); label.textContent = 'On this page'; toc.append(label);
    page.querySelectorAll('.params-title,.step-title,h2,.code-block-header').forEach((heading,index) => {
      heading.id ||= page.id + '-topic-' + index;
      const link = document.createElement('a'); link.href = '#' + heading.id;
      link.textContent = heading.matches('.code-block-header') ? 'Code example' : heading.textContent.trim(); toc.append(link);
    });
    pagination.replaceChildren(); const index = pages.indexOf(page);
    for (const [offset,prefix] of [[-1,'← Previous: '],[1,'Next: ']]) {
      const other = pages[index + offset]; if (!other) continue;
      const link = document.createElement('a'); link.href = '#' + other.id; link.textContent = prefix + title(other); pagination.append(link);
    }
    closeMenu();
    requestAnimationFrame(() => {
      if (target && target !== page) target.scrollIntoView({block:'start'}); else window.scrollTo(0,0);
    });
  }
  window.addEventListener('hashchange',render); render();
  window.filterNav = () => {
    const query = document.getElementById('sbSearch').value.trim().toLowerCase(); let count = 0;
    links.forEach(link => {
      const page = document.getElementById(link.hash.slice(1));
      const match = !query || (link.textContent + ' ' + (page?.textContent || '')).toLowerCase().includes(query);
      link.parentElement.style.display = match ? '' : 'none'; if (match) count++;
    });
    document.querySelectorAll('.sb-group').forEach(group => group.hidden = ![...group.querySelectorAll('li')].some(li => li.style.display !== 'none'));
    document.querySelector('.search-empty').hidden = count > 0;
  };
})();
