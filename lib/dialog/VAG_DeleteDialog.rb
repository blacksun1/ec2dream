require 'rubygems'
require 'fox16'
require 'common/error_message'

include Fox

class VAG_DeleteDialog < FXDialogBox

  def initialize(owner, curr_item)
    @ec2_main = owner
    @delete_item = curr_item
    @deleted = false
    answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm delete","Confirm delete of Vagrantfie for Server "+@delete_item)
    if answer == MBOX_CLICKED_YES
      folder = "#{$ec2_main.settings.get('VAGRANT_REPOSITORY')}/#{@delete_item}"
      begin
        FileUtils.rm_rf folder
        @deleted = true
        if @deleted == false
          error_message("Server Vagrant Configuration Deletion failed","Server Vagrant Configuration Deletion failed")
        end
      rescue
        error_message("Server Vagrant Configuration Deletion failed",$!)
      end
    end
  end
  def deleted
    @deleted
  end
  def success
    @deleted
  end
end
