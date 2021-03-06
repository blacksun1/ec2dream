
require 'rubygems'
require 'fox16'
require 'common/EC2_Properties'
require 'common/error_message'
require 'common/edit'

include Fox

class CF_CreateDialog < FXDialogBox

  def initialize(owner, curr_item=nil)
    puts "CF_CreateDialog.initialize"
    @saved = false
    @ec2_main = owner
    @magnifier = @ec2_main.makeIcon("magnifier.png")
    @magnifier.create
    @script_edit = @ec2_main.makeIcon("script_edit.png")
    @script_edit.create
    super(@ec2_main, "Create Stack Configuration", :opts => DECOR_ALL, :width => 600, :height => 275)
    page1 = FXVerticalFrame.new(self, LAYOUT_FILL, :padding => 0)
    frame1 = FXMatrix.new(page1, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "Stack Name" )
    stack_name = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "cfndsl File" )
    frame1b = FXHorizontalFrame.new(frame1,LAYOUT_FILL_X, :padding => 0)
    cfndsl_file = FXTextField.new(frame1b, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT)
    cfndsl_file_button = FXButton.new(frame1b, "", :opts => BUTTON_TOOLBAR)
    cfndsl_file_button.icon = @magnifier
    cfndsl_file_button.tipText = "Browse..."
    cfndsl_file_button.connect(SEL_COMMAND) do
      dialog = FXFileDialog.new(frame1b, "Select cfndsl file")
      dialog.patternList = [
        "cfndsl Files (*.*)"
      ]
      dialog.selectMode = SELECTFILE_EXISTING
      if dialog.execute != 0
        cfndsl_file.text = dialog.filename
      end
    end
    cfndsl_edit_button = FXButton.new(frame1b, "", :opts => BUTTON_TOOLBAR)
    cfndsl_edit_button.icon = @script_edit
    cfndsl_edit_button.tipText = "Edit cfndsl..."
    cfndsl_edit_button.connect(SEL_COMMAND) do |sender, sel, data|
      edit(cfndsl_file.text)
    end
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "cfndsl Parameters" )
    cfndsl_parameters = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Pretty Print JSON" )
    pretty_print_json = FXComboBox.new(frame1, 15, :opts => COMBOBOX_STATIC|COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
    pretty_print_json.numVisible = 2
    pretty_print_json.appendItem("true")
    pretty_print_json.appendItem("false")
    pretty_print_json.setCurrentItem(0)
    FXLabel.new(frame1, "" )

    FXLabel.new(frame1, "Template File" )
    frame1a = FXHorizontalFrame.new(frame1,LAYOUT_FILL_X, :padding => 0)
    template_file = FXTextField.new(frame1a, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT)
    template_file_button = FXButton.new(frame1a, "", :opts => BUTTON_TOOLBAR)
    template_file_button.icon = @magnifier
    template_file_button.tipText = "Browse..."
    template_file_button.connect(SEL_COMMAND) do
      dialog = FXFileDialog.new(frame1a, "Select template file")
      dialog.patternList = [
        "Template Files (*.*)"
      ]
      dialog.selectMode = SELECTFILE_EXISTING
      if dialog.execute != 0
        template_file.text = dialog.filename
      end
    end
    template_edit_button = FXButton.new(frame1a, "", :opts => BUTTON_TOOLBAR)
    template_edit_button.icon = @script_edit
    template_edit_button.tipText = "Edit Template..."
    template_edit_button.connect(SEL_COMMAND) do |sender, sel, data|
      edit(template_file.text)
    end
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Parameters" )
    parameters = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Disable Rollback" )
    disable_rollback = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Timeout in Minutes" )
    timeout_in_minutes = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    frame2 = FXHorizontalFrame.new(page1,LAYOUT_FILL, :padding => 0)
    save = FXButton.new(frame2, "   &Save   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    save.connect(SEL_COMMAND) do |sender, sel, data|
      if stack_name.text == nil or stack_name.text == ""
        error_message("Error","Stack Name not specified")
      else
        save_stack(stack_name.text,cfndsl_file.text,cfndsl_parameters.text,pretty_print_json,template_file.text,parameters.text,disable_rollback.text,timeout_in_minutes.text)
        if @saved == true
          self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
        end
      end
    end
    if curr_item != nil and curr_item != ""
      r = get_stack(curr_item)
      if r['stack_name'] != nil and r['stack_name'] != ""
        stack_name.text = r['stack_name']
        cfndsl_file.text = r['cfndsl_file']
        cfndsl_parameters.text = r['cfndsl_parameters']
        if r['pretty_print_json'] == 'false'
          pretty_print_json.setCurrentItem(1)
        else
          pretty_print_json.setCurrentItem(0)
        end
        template_file.text = r['template_file']
        parameters.text = r['parameters']
        if r['disable_rollback'] != nil and r['disable_rollback'] != ""
          disable_rollback.text = r['disable_rollback']
        else
          disable_rollback.text = ""
        end
        if r['timeout_in_minutes'] != nil and r['timeout_in_minutes'] != ""
          timeout_in_minutes.text = r['timeout_in_minutes']
        else
          timeout_in_minutes.text = ""
        end
      end
    end
  end

  def get_stack(stack_name)
    folder = "cf_templates"
    properties = {}
    loc = EC2_Properties.new
    if loc != nil
      properties = loc.get(folder, stack_name)
    end
    return properties
  end

  def save_stack(stack_name,cfndsl_file,cfndsl_parameters,pretty_print_json,template_file,parameters,disable_rollback,timeout_in_minutes)
    folder = "cf_templates"
    loc = EC2_Properties.new
    if loc != nil
      begin
        properties = {}
        properties['stack_name']=stack_name
        properties['cfndsl_file']=cfndsl_file
        properties['cfndsl_parameters']=cfndsl_parameters
        if pretty_print_json.itemCurrent?(1)
          properties['pretty_print_json'] = 'false'
        else
          properties['pretty_print_json'] = 'true'
        end
        properties['template_file']=template_file
        properties['parameters']=parameters
        if disable_rollback != nil and disable_rollback != ""
          properties['disable_rollback'] = disable_rollback
        end
        if timeout_in_minutes != nil and timeout_in_minutes != ""
          properties['timeout_in_minutes'] = timeout_in_minutes
        end
        @saved = loc.save(folder, stack_name, properties)
        if @saved == false
          error_message("Save Stack Configuration Failed","Save Stack Configuration  Stack Failed")
          return
        end
      rescue
        error_message("Save Stack Configuration  Failed",$!)
        return
      end
    end
  end

  def saved
    @saved
  end

  def success
    @saved
  end

end
