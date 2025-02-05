const mobileMenu = () => {
    const nav = document.querySelector('.navmenu');
    const list = nav.querySelector('ul');
    const button = document.querySelector('.hamburger');
    console.log("i found the button", button);
  
    if (!nav || !list || !button) {
        console.error("Elements for mobile menu not found. Check HTML structure or IDs.");
        return;
    }
  
    button.addEventListener('click', () => {
        button.classList.toggle('mobile-menu-open');
        list.classList.toggle('mobile-menu-open');
    });
  
    document.addEventListener('keyup', (e) => {
        if (e.code === 'Escape' && list.classList.contains('mobile-menu-open')) {
            button.classList.remove('mobile-menu-open');
            list.classList.remove('mobile-menu-open');
        }
    });
};
  
export default mobileMenu;
  