import { Controller } from '@hotwired/stimulus';
import { debounce } from 'utils/debounce';

export default class extends Controller {
  initialize() {
    this.submit = this.submit.bind(this);
  }

  connect() {
    this.submit = debounce(this.submit, 300);
  }

  submit() {
    this.element.requestSubmit();
  }

  reset() {
    this.element.reset();
    this.element.requestSubmit();
  }
}
