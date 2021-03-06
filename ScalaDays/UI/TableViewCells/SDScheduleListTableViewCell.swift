/*
* Copyright (C) 2015 47 Degrees, LLC http://47deg.com hello@47deg.com
*
* Licensed under the Apache License, Version 2.0 (the "License"); you may
* not use this file except in compliance with the License. You may obtain
* a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

import UIKit

protocol SDScheduleListTableViewCellDelegate {
    func didSelectVoteButtonWithEvent(_ event: Event, conferenceId: Int)
}

class SDScheduleListTableViewCell: UITableViewCell {

    let kDefaultHeightForLbl: CGFloat = 15.0
    let kDefaultHeightForViewSpeaker: CGFloat = 36.0
    let kDefaultHeightForImgSpeaker: CGFloat = 30.0
    let kDefaultHeightForLblTwitter: CGFloat = 17.0
    let kDefaultBottomSpaceForLbl: CGFloat = 4.0
    let kDefaultTopSpaceForLblTwitter: CGFloat = 2.0
    let kDefaultTopSpaceForTitle: CGFloat = 6.0
    let kWidthOfTimeContainer: CGFloat = 80.0
    let kDefaultHorizontalLeading: CGFloat = 15.0
    let kDefaultHorizontalTrailing: CGFloat = 40.0
    let kDefaultMaxAlphaForSelectionBG: CGFloat = 0.3
    let kBtnVoteHeight: CGFloat = 30.0
    let kBtnEditVoteHeight: CGFloat = 26.0
    let kBtnEditVoteDisabledAlpha: CGFloat = 0.5
    let kEventTypeConference = 2
    let kBntVoteCornerRadius: CGFloat = 3.0

    @IBOutlet weak var lblTrack: UILabel!
    @IBOutlet weak var lblLocation: UILabel!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblTime: UILabel!
    @IBOutlet weak var viewTime: UIView!
    @IBOutlet weak var selectedBGView: UIView!
    @IBOutlet weak var imgFavoriteIcon: UIImageView!
    @IBOutlet weak var viewSpeaker: UIView!
    @IBOutlet weak var btnVote: UIButton!
    @IBOutlet weak var btnEditVote: UIButton!

    @IBOutlet weak var constraintForLblTrackHeight: NSLayoutConstraint!
    @IBOutlet weak var constraintForLblTrackBottomSpace: NSLayoutConstraint!
    @IBOutlet weak var constraintForLblLocationHeight: NSLayoutConstraint!
    @IBOutlet weak var constraintForLblLocationBottomSpace: NSLayoutConstraint!
    @IBOutlet weak var constraintForBtnVoteHeight: NSLayoutConstraint!
    @IBOutlet weak var constraintForBtnEditVoteHeight: NSLayoutConstraint!
    @IBOutlet weak var constraintForLblTitleBottomSpace: NSLayoutConstraint!
    @IBOutlet weak var constraintForViewSpeakerHeight: NSLayoutConstraint!
    
    var delegate: SDScheduleListTableViewCellDelegate?
    var eventData: (event: Event, conferenceId: Int)?
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        self.selectedBGView.alpha = highlighted ? kDefaultMaxAlphaForSelectionBG : 0
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        self.selectedBGView.alpha = selected ? kDefaultMaxAlphaForSelectionBG : 0
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        lblTitle?.preferredMaxLayoutWidth = self.frame.size.width - kWidthOfTimeContainer - kDefaultHorizontalLeading - kDefaultHorizontalTrailing
    }

    func drawEventData(_ event: Event, conferenceId: Int) {
        if let timeZoneName = DataManager.sharedInstance.conferences?.conferences[DataManager.sharedInstance.selectedConferenceIndex].info.utcTimezoneOffset,
            let startDate = SDDateHandler.sharedInstance.parseScheduleDate(event.startTime),
            let localStartDate = SDDateHandler.convertDateToLocalTime(startDate, timeZoneName: timeZoneName),
            let endDate = SDDateHandler.sharedInstance.parseScheduleDate(event.endTime),
            let localEndDate = SDDateHandler.convertDateToLocalTime(endDate, timeZoneName: timeZoneName),
            let currentDate = SDDateHandler.convertDateToLocalTime(Date(), timeZoneName: timeZoneName) {
            
                let isSafeToVote = SDDateHandler.isSafeToVoteForConferenceWithDate(localEndDate, fromReferenceDate: currentDate) && event.type == kEventTypeConference
                // Vote button configuration:
                lblTime.text = SDDateHandler.sharedInstance.hoursAndMinutesFromDate(localStartDate)
                viewTime.backgroundColor = SDDateHandler.sharedInstance.isCurrentDateActive(event.startTime, endTime: event.endTime) ? colorScheduleTimeActive : colorScheduleTime
                let btnVoteParams : (hidden: Bool, height: CGFloat) =
                    isSafeToVote ?
                        (false, kBtnVoteHeight) :
                        (true, 0)
                btnVote.isHidden = btnVoteParams.hidden
                constraintForBtnVoteHeight.constant = btnVoteParams.height
                
                // Edit vote button configuration:
                if let votes = StoringHelper.sharedInstance.loadVotesData(),
                    let voteDict = votes.filter({(vote: (key: String, v: Vote)) in vote.v.conferenceId == conferenceId && vote.v.talkId == event.id}).first {
                        let (_, vote) = voteDict
                        btnEditVote.isHidden = false
                        btnVote.isHidden = true
                        constraintForBtnEditVoteHeight.constant = kBtnEditVoteHeight
                        if let voteValue = VoteType(rawValue: vote.voteValue) {
                            btnEditVote.setImage(UIImage(named: voteValue.iconNameForVoteType()), for: UIControl.State())
                        }
                        let (enabled, alpha) = isSafeToVote ? (true, kAlphaValueFull) : (false, kBtnEditVoteDisabledAlpha)
                        btnEditVote.isEnabled = enabled
                        btnEditVote.alpha = alpha
                        
                } else {
                    btnEditVote.isHidden = true
                    constraintForBtnEditVoteHeight.constant = 0
                }
        }      
        

        lblTitle.text = event.title
        if let eventTrack = event.track {
            constraintForLblTrackHeight.constant = kDefaultHeightForLbl
            constraintForLblTrackBottomSpace.constant = kDefaultBottomSpaceForLbl
            lblTrack.text = eventTrack.name
        } else {
            constraintForLblTrackHeight.constant = 0
            constraintForLblTrackBottomSpace.constant = 0
            lblTrack.text = ""
        }

        if let eventLocation = event.location {
            constraintForLblLocationHeight.constant = kDefaultHeightForLbl
            constraintForLblLocationBottomSpace.constant = kDefaultTopSpaceForTitle
            lblLocation.text = NSLocalizedString("schedule_location_title", comment: "") + eventLocation.name
        } else {
            constraintForLblLocationHeight.constant = 0
            constraintForLblLocationBottomSpace.constant = 0
            lblLocation.text = ""
        }

        let spaceAboveTitleLabel = constraintForLblLocationBottomSpace.constant + constraintForLblLocationHeight.constant + constraintForLblTrackBottomSpace.constant + constraintForLblTrackHeight.constant
        let spaceBelowTitleLabelIfVoteAvailable = (btnVote.isHidden && btnEditVote.isHidden) ? 0 : btnVote.bounds.height - spaceAboveTitleLabel
        
        if let speakers = event.speakers {
            for view in viewSpeaker.subviews {
                view.removeFromSuperview()
            }
            if (speakers.count < 1) {
                constraintForViewSpeakerHeight.constant = spaceBelowTitleLabelIfVoteAvailable
            } else {
                let lastSpeakerBottomPos = speakers.enumerated().reduce(0, { (speakerBottomPos: CGFloat, currentIterator: (index: Int, speaker: Speaker)) -> CGFloat in
                    let speakerView = SDSpeakerScheduleView(frame: CGRect(x: 0, y: speakerBottomPos, width: screenBounds.width, height: 0))
                    speakerView.drawSpeakerData(currentIterator.speaker)
                    viewSpeaker.addSubview(speakerView)
                    
                    let height = speakerView.contentHeight()
                    speakerView.frame = CGRect(x: 0, y: speakerBottomPos, width: screenBounds.width, height: height)
                    return speakerBottomPos + height
                })
                constraintForViewSpeakerHeight.constant = lastSpeakerBottomPos
            }
        } else {
            constraintForViewSpeakerHeight.constant = spaceBelowTitleLabelIfVoteAvailable
            for view in viewSpeaker.subviews {
                view.removeFromSuperview()
            }
        }
        
        eventData = (event, conferenceId)
        btnVote.layer.cornerRadius = kBntVoteCornerRadius
        btnVote.layer.masksToBounds = true
        imgFavoriteIcon.isHidden = true
        layoutSubviews()
    }
    
    @IBAction func didTapBtnVote(_ sender: AnyObject) {
        if let event = eventData?.event,
            let conferenceId = eventData?.conferenceId {
            delegate?.didSelectVoteButtonWithEvent(event, conferenceId: conferenceId)
        }
    }
}
