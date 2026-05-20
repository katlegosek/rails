import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static values = {
    id: String,
  };

  open() {
    const openDialogs = document.querySelectorAll('dialog[open]');
    for (const dialog of openDialogs) {
      dialog.close();
    }

    const dialogId = this.idValue;
    const dialog = document.getElementById(dialogId);

    if (dialog && dialog.tagName.toLowerCase() === 'dialog') {
      dialog.showModal();
    }
  }
}
