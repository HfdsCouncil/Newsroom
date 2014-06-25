/*
 * Fix to allow Date.now() to work in IE 8 and below.
 */
Date.now = Date.now || function () { return +new Date; };

/*
 * Take passed object (obj) and return false if it doesn't exist
 */
function checkObjectExists(obj) {
  if (!document.getElementById(obj)) {
    //console.log('Object does not exist');
    return false;
  } else {
    //console.log('Object exists');
    return true;
  }
}

(function () {
  /*
  * Toggle the appearance of the menu in the responsive layout
  */

  if (checkObjectExists('js-mobile-menu-toggle')) {

    var mobileMenuToggle = document.getElementById('js-mobile-menu-toggle'),
        innerWrapper = document.getElementById('js-inner-wrapper');

    mobileMenuToggle.onclick = function () {

      var innerWrapperClassName = innerWrapper.className;

      if (innerWrapperClassName === 'inner-wrapper') {
        innerWrapper.className += ' active';
      } else {
        innerWrapper.className = 'inner-wrapper';
      }
      return false;
    }

  }

})();

(function () {
  /*
   * Add a print button to every page and open the browser print diologue when clicked
   */

  if (checkObjectExists('js-page-actions')) {

    var pageActions = document.getElementById('js-page-actions'),
        printLinkHtml = '<li><a href="#print" id="js-page-actions__print" class="page-actions__print secondary-button">Print</a></li>';

    pageActions.innerHTML += printLinkHtml;

    if (checkObjectExists('js-page-actions__print')) {

      var pageActionsPrint = document.getElementById('js-page-actions__print');

      pageActionsPrint.onclick = function () {
        window.print();
        return false;
      }

    }

  }

})();