########################################################################################################################
# *Copyright*(c)::
#   2019 by FujiFilm SonoSite Incorporated
#   Contains Confidential Information - All Rights Reserved
#
# *Filename*::   usb-export-studies.rb
# *Author(s)*::  Helen Canzler
#
# *Description*::
#    Check if DICOM archiver is setup or not
#    Enable auto generate MRN and Auto-save patient form
#    for 1 to # of USB export iteration
#       Create 1 up to 3 studies. Save up to 2 images and up to 2 10s clips
#       Check if export is in-progress
#           Sleep
#           Modify exam
#           Go to random imaging mode, save an image
#           Go to random view
#           Go to random clip mode, save a clip
#       End study
#       Go to study list, select all studies export to usb with patient info included
#
########################################################################################################################

if __FILE__ == $0
  raise 'No runnable code in ' + __FILE__ + ' File requires the automation test framework.'

end

# Include required libraries
require_relative './../../../lib/helper-methods.rb'

# main test class
class UsbExportStudies < SonoSiteSystem::Test
  include GetState
  include SetState

  def initialize(script_name)
    super
    @num_studies = @test_info.test_inputs[:num_studies]
    @num_exports = @test_info.test_inputs[:num_exports]
  end

  def setup
  end

  def execute
    goto_2D
    goto_view(VIEW['EXAM'])
    num_active_scanhead = get_active_transducer_bays.size

    current_active_dicom = dicom_active
    dicom_archive_active = current_active_dicom.include?(DICOM_TYPE['ARCHIVER'])
    dicom_archive_storage_commit_active = current_active_dicom.include?(DICOM_TYPE['STORAGE_COMMIT'])
    dicom_archive_active ? (show_log 'DICOM archive is configured on system') : (show_log 'DICOM archive is NOT configured on system')
    dicom_archive_storage_commit_active ? (show_log 'DICOM storage commit is configured on system') : (show_log 'DICOM storage commit is NOT configured on system')

    show_log_banner "\nDelete All studies, enable auto save patient form & auto generate MRN, set clip type to 10s Retrospective"
    delete_all_studies
    study_list_sort(SORT_SELECTOR['DATETIME'], 'Descending')

    set_generate_patient_mrn('Checked')
    set_auto_save_ptnt_form('On')
    goto_2D
    set_time_clip_method_type(CLIP['RETROSPECTIVE'], 4) # 4 is the combo box index of 10s clip

    # Prepare the different test options, with some 'scenarios' in addition to predefined views
    views_predefined = [VIEW['PATIENT'], VIEW['STUDYLIST'], VIEW['REVIEW'], VIEW['SETTINGS']]
    scenarios_LMiR = [:scenario_LMiR_review, :scenario_LMiR_edit]

    # Important transitions first
    initial_sequence = [views_predefined[0], :scenario_LMiR_review, :scenario_LMiR_review, views_predefined[1],
                        views_predefined[2], :scenario_LMiR_edit, :scenario_LMiR_review, :scenario_LMiR_edit,
                        :scenario_LMiR_edit, views_predefined[3]]
    # Use this instead if fully random choices are preferred
    # initial_sequence = []

    show_log("Will perform #{@num_exports} exports.")
    @num_exports.times do |iteration|
      show_log("Performing export no. #{iteration}")
      change_scanhead if num_active_scanhead > 1 # change scanhead if there's more than one attached
      img_modes = get_image_modes
      clip_modes = get_clip_modes
      create_studies(clip_modes, img_modes, rand(2)+1, iteration, scanhead.selected_exam)

      show_log '*** Waiting for USB export to complete. Perform operations while waiting ***'
      wait = 0
      step = 0
      while clinical_display.icons.names.any?{|icon_name| USB_EXPORT_ICONS.include?(icon_name)}
        show_log "Performing an operation. Total wait time #{wait += 60} seconds"
        sleep(60)

        change_scanhead if num_active_scanhead > 1 # change scanhead if there's more than one attached

        goto_imaging
        scanhead.set_exam(scanhead.supported_exams.sample)
        show_log "Exam selected: #{scanhead.selected_exam}"

        img_modes = get_image_modes
        clip_modes = get_clip_modes

        mode_to_test = img_modes.sample
        setup_mode(mode_to_test)
        eval(%w(depth_add depth_subtract).sample) if %w(B-MODE CPD Color Variance).include?(mode_to_test)

        save_image

        # Choose test option
        if (not initial_sequence.nil?) and (step < initial_sequence.length)
          # Choose a view/scenario from the initial sequence (if any)
          test_option = initial_sequence[step]
          show_log "Choosing 'test option' from initial sequence, step [#{step}]: #{test_option}"
        else
          # Pick a view or scenario at random
          test_option = (views_predefined | scenarios_LMiR).sample
          show_log "Choosing 'test option' at random, step [#{step}]: #{test_option}"
        end
        step += 1

        # Use the test option: 'exercise a LMiR scenario' or use a regular view
        case test_option
        when :scenario_LMiR_review
          drive_scenario_LMiR_review
        when :scenario_LMiR_edit
          drive_scenario_LMiR_edit
        else # regular view
          if test_option == VIEW['REVIEW']
            show_log("Special handling of '#{test_option}', will wait for thumbnail...")
            wait_thumbnail = 0
            # wait for a thumbnail to be available before going to Review due to possible delay during USB export
            while control_panel.imaging_thumbnails.size < 1
              sleep(2)
              show_log "Total wait time for thumbnail: #{wait_thumbnail += 2} seconds"
            end
            show_log('Found thumbnail.')
          end
          goto_view(test_option)
        end

        exit_view(navigator.view)
        accept_dialog
        setup_mode(clip_modes.sample)
        sleep(SLEEP_DELAY['med']) # acquire some data
        save_clip
        sleep(SLEEP_DELAY['long']) # allow save to complete
        show_log "Go to 'Report & Worksheet' and select each tab to generate the appropriate files if in an active study"
        select_all_worksheet_tabs if in_active_study?
        end_study
      end

      show_log_banner "\nSelect All studies, export to USB."
      goto_study_list

      # If DICOM archive is configured on the system, wait for archiving to complete
      num_studies = grids.row_count(GRIDS['STUDY_LIST_BOX'])
      if (dicom_archive_active || dicom_archive_storage_commit_active) and (num_studies > 0)
        dicom_archive_wait = 0
        loop do
          # Check for the archive status of the last completed study only. Archiving is in chronological order.
          # Assumes that the study list is in anti-chronological(default) order.
          archive_status = grids.get_row(GRIDS['STUDY_LIST_BOX'], 0)[7]
          show_log "DEBUG: Status of study in row 0 = #{archive_status}"

          break if archive_status.include?('Succeeded')

          show_log "Waiting #{dicom_archive_wait += 30} seconds for DICOM archive and/or storage commit to complete"
          sleep(30)
        end
      end

      # Initiate USB export. Skip USB export if one is already in progress
      unless clinical_display.icons.names.any?{|icon_name| USB_EXPORT_ICONS.include?(icon_name)}
        show_log "*** USB Export iteration: #{iteration+1} ***"
        select_all_studies
        sleep(SLEEP_DELAY['med'])
        export_to_usb_include_patient_info
      end

      goto_imaging
    end

    show_log '*** Waiting for last USB export to complete ***'
    wait = 0
    while clinical_display.icons.names.any?{|icon_name| USB_EXPORT_ICONS.include?(icon_name)}
      sleep(60)
      show_log "Total wait time #{wait += 60} seconds"
    end

    test_eq("Completed #{@num_exports} exports without an assert/failure", true, 'Actual:', true)
  end

  def tear_down
    goto_2D
  end

  private

  def create_studies(clip_modes, img_modes, num_studies, export_iteration, exam)
    num_studies.times do |count|
      num_clips = rand(2)
      num_imgs = rand(2)

      show_log_banner "\nRegistering Patient #{export_iteration}_#{count} and saving #{num_clips} clips, #{num_imgs} images."
      goto_view(VIEW['PATIENT'])
      text_boxes.set_text(TXT_BOX['LASTNAME'], "Patient_#{export_iteration}_#{count}")
      text_boxes.set_text(TXT_BOX['FIRSTNAME'], generate_random_string(5))
      buttons.press(BTN['SCAN'])

      show_log "Exam selected: #{exam}"

      num_clips.times do
        mode = clip_modes.sample
        capture_dual_image = (mode =~ /B-MODE|Color|CPD|Variance/? true : false)

        show_log "State transition: set mode to #{mode}"
        setup_clip(mode)
        sleep(10)
        save_clip
        sleep 1 # Allow the clip save to complete

        if capture_dual_image
          show_log "Saving 1 additional clip for mode #{mode} with dual display or color compare enabled"
          setup_clip(mode, set_dual_image=true)
          sleep(10)
          save_clip
          sleep 1 # Allow the clip save to complete
        end
      end

      num_imgs.times do
        mode = img_modes.sample
        capture_dual_image = (mode =~ /B-MODE|Color|CPD|Variance/? true : false)

        show_log "State transition: set mode to #{mode}"
        setup_image(mode, exam)
        save_image

        if capture_dual_image
          show_log "Saving 1 additional image for mode #{mode} with dual display or color compare enabled"
          setup_image(mode, exam, set_dual_image=true)
          save_image
        end
      end

      show_log "Go to 'Report & Worksheet' and select each tab to generate the appropriate files if in an active study"
      select_all_worksheet_tabs if in_active_study?

      end_study
      sleep(SLEEP_DELAY['short'])
    end
  end

  def drive_scenario_LMiR_review
    show_log('Entering LMiR review mode...')
    # These are steps to take a simple video view and activate LMiR review mode
    # first we drive to 'review' mode (but not actual 'LMiR review')
    create_patient({TXT_BOX['LASTNAME'] => 'ClosedShutdownInLMiR', 'NumberImages' => 2})
    end_study; sleep 1
    goto_imaging; sleep 1
    goto_study_list; sleep 1
    select_study(0); sleep 1
    goto_review; sleep 1
    # up to this point we are in 'plain review' mode
    # and the next steps take us to actual 'LMiR review' mode
    caliper; sleep 1
    sleep(SLEEP_DELAY['med']) # acquire some data
    save_image; sleep 1
    log('In LMiR review mode.')
  end

  def drive_scenario_LMiR_edit
    show_log('Entering LMiR edit mode... first into LMiR review mode...')
    drive_scenario_LMiR_review
    show_log('... after LMiR review mode... now entering LMiR edit mode...')
    # Once in 'LMiR review' mode, perform some 'edits' to change to 'LMiR edit' mode
    label; sleep(1)
    show_log_banner "\nCycle through each Annotation (Text, Pictos, Arrows), add one of each, save, remove all labels."
    add_text; sleep 1
    add_picto; sleep 1
    add_arrow; sleep 1
    save_image; sleep 1
    save_image; sleep 1
    add_text; sleep 1
    save_image; sleep 1
    buttons.press(BTN['CLEAR_ALL_LABELS']); sleep 1
    add_picto; sleep 1
    log('In LMiR edit mode.')
  end
end
