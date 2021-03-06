import remote from 'remote';
import TrayStore from './tray-store';
const Tray = remote.require('tray');


class SystemTray {

  constructor(platform) {
    this._platform = platform;
    this._store = new TrayStore(this._platform);
    this._tray = new Tray(this._store.icon());
    this._tray.setToolTip(this._store.tooltip());

    const menu = this._store.menu();
    if (menu != null) this._tray.setContextMenu(menu);

    this._unsubscribe = this._addEventListeners();
  }

  _addEventListeners() {
    this._tray.addListener('clicked', this._onClicked.bind(this));
    const unsubClicked = ()=> this._tray.removeListener('clicked', this._onClicked);
    const unsubStore = this._store.listen(this._onChange.bind(this));
    return ()=> {
      unsubClicked();
      unsubStore();
    };
  }

  _onClicked() {
    if (this._platform !== 'darwin') {
      atom.focus();
    }
  }

  _onChange() {
    const icon = this._store.icon();
    const tooltip = this._store.tooltip();
    this._tray.setImage(icon);
    this._tray.setToolTip(tooltip);
  }

  destroy() {
    this._tray.destroy();
    this._unsubscribe();
  }
}

export default SystemTray;
