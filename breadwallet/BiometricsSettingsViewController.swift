//
//  BiometricsSettingsViewController.swift
//  breadwallet
//
//  Created by Adrian Corscadden on 2017-03-27.
//  Copyright © 2017-2019 Breadwinner AG. All rights reserved.
//

import UIKit
import LocalAuthentication
import BRCore

class BiometricsSettingsViewController: UIViewController, Subscriber {

    lazy var biometricType = LAContext.biometricType()
        
    var explanatoryText: String {
        return biometricType == .touch ? S.TouchIdSettings.explanatoryText : S.FaceIDSettings.explanatoryText
    }
    
    var unlockTitleText: String {
        return biometricType == .touch ? S.TouchIdSettings.unlockTitleText : S.FaceIDSettings.unlockTitleText
    }
    
    var transactionsTitleText: String {
        return biometricType == .touch ? S.TouchIdSettings.transactionsTitleText : S.FaceIDSettings.transactionsTitleText
    }
    
    var imageName: String {
        return biometricType == .touch ? "TouchId-Large" : "FaceId-Large"
    }
    
    private let imageView = UIImageView()
    
    private let explanationLabel = UILabel.wrapping(font: Theme.body1, color: Theme.secondaryText)
    
    // Toggle for enabling Touch ID or Face ID to unlock the BRD app.
    private let unlockTitleLabel = UILabel.wrapping(font: Theme.body1, color: Theme.primaryText)
    
    // Toggle for enabling Touch ID or Face ID for sending money.
    private let transactionsTitleLabel = UILabel.wrapping(font: Theme.body1, color: Theme.primaryText)

    private let unlockToggle = UISwitch()
    private let transactionsToggle = UISwitch()
    
    private let unlockToggleSeparator = UIView()
    private let transactionsToggleSeparator = UIView()
    
    private var hasSetInitialValueForUnlockToggle = false
    private var hasSetInitialValueForTransactions = false
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setWhiteStyle()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        [imageView,
         explanationLabel, unlockTitleLabel, transactionsTitleLabel,
         unlockToggle, transactionsToggle,
         unlockToggleSeparator, transactionsToggleSeparator].forEach({ view.addSubview($0) })
        
        setUpAppearance()
        addConstraints()
        setData()
        addFaqButton()
    }
    
    private func setUpAppearance() {
        view.backgroundColor = Theme.primaryBackground
        explanationLabel.textAlignment = .center
        
        unlockToggleSeparator.backgroundColor = Theme.tertiaryBackground
        transactionsToggleSeparator.backgroundColor = Theme.tertiaryBackground
    }
    
    private func addConstraints() {
        
        let screenHeight: CGFloat = UIScreen.main.bounds.height
        let topMarginPercent: CGFloat = 0.08
        let imageTopMargin: CGFloat = (screenHeight * topMarginPercent)
        let leftRightMargin: CGFloat = 40.0
        
        imageView.constrain([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: imageTopMargin)
            ])
        
        explanationLabel.constrain([
            explanationLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: leftRightMargin),
            explanationLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -leftRightMargin),
            explanationLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: C.padding[2])
            ])
        
        //
        // unlock BRD toggle and associated labels
        //
        
        unlockTitleLabel.constrain([
            unlockTitleLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: C.padding[2]),
            unlockTitleLabel.topAnchor.constraint(equalTo: explanationLabel.bottomAnchor, constant: C.padding[5])
            ])
        
        unlockToggle.constrain([
            unlockToggle.centerYAnchor.constraint(equalTo: unlockTitleLabel.centerYAnchor),
            unlockToggle.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -C.padding[2]),
            unlockToggle.leftAnchor.constraint(greaterThanOrEqualTo: unlockTitleLabel.rightAnchor, constant: C.padding[1])
            ])
        
        unlockToggleSeparator.constrain([
            unlockToggleSeparator.topAnchor.constraint(equalTo: unlockToggle.bottomAnchor, constant: C.padding[1]),
            unlockToggleSeparator.leftAnchor.constraint(equalTo: view.leftAnchor),
            unlockToggleSeparator.rightAnchor.constraint(equalTo: view.rightAnchor),
            unlockToggleSeparator.heightAnchor.constraint(equalToConstant: 1.0)
            ])
        
        //
        // send money toggle and associated labels
        //

        transactionsTitleLabel.constrain([
            transactionsTitleLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: C.padding[2]),
            transactionsTitleLabel.topAnchor.constraint(equalTo: unlockTitleLabel.bottomAnchor, constant: C.padding[4])
            ])
        
        transactionsToggle.constrain([
            transactionsToggle.centerYAnchor.constraint(equalTo: transactionsTitleLabel.centerYAnchor),
            transactionsToggle.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -C.padding[2]),
            transactionsToggle.leftAnchor.constraint(greaterThanOrEqualTo: transactionsTitleLabel.rightAnchor, constant: C.padding[1])
            ])
        
        transactionsToggleSeparator.constrain([
            transactionsToggleSeparator.topAnchor.constraint(equalTo: transactionsToggle.bottomAnchor, constant: C.padding[1]),
            transactionsToggleSeparator.leftAnchor.constraint(equalTo: view.leftAnchor),
            transactionsToggleSeparator.rightAnchor.constraint(equalTo: view.rightAnchor),
            transactionsToggleSeparator.heightAnchor.constraint(equalToConstant: 1.0)
            ])

    }

    private func setData() {
        imageView.image = UIImage(named: imageName)
        explanationLabel.text = explanatoryText
        unlockTitleLabel.text = unlockTitleText
        transactionsTitleLabel.text = transactionsTitleText
        
        // listen for changes to the default/unlock biometrics setting
        Store.subscribe(self, selector: { $0.isBiometricsEnabled != $1.isBiometricsEnabled }, callback: { [weak self] in
            guard let `self` = self else { return }
            
            self.unlockToggle.isOn = $0.isBiometricsEnabled
            
            // The transactions toggle is controlled by on/off state of the unlock toggle.
            // That is, the transactions toggle can only be ON and enabled if the unlock toggle is ON.
            if !$0.isBiometricsEnabled {
                self.transactionsToggle.isEnabled = false
                self.transactionsToggle.setOn(false, animated: true)
            } else {
                self.transactionsToggle.isEnabled = true
            }
            
            if !self.hasSetInitialValueForUnlockToggle {
                self.hasSetInitialValueForUnlockToggle = true
                self.unlockToggle.sendActions(for: .valueChanged)
            }
        })

        // listen for changes to the transactions biometrics setting
        Store.subscribe(self, selector: { $0.isBiometricsEnabledForTransactions != $1.isBiometricsEnabledForTransactions }, callback: { [weak self] in
            guard let `self` = self else { return }
            
            self.transactionsToggle.isOn = $0.isBiometricsEnabledForTransactions
            
            if !self.hasSetInitialValueForTransactions {
                self.hasSetInitialValueForTransactions = true
                self.transactionsToggle.sendActions(for: .valueChanged)
            }
        })
        
        unlockToggle.valueChanged = { [weak self] in
            guard let `self` = self else { return }
            self.toggleChanged(toggle: self.unlockToggle)
        }
        
        transactionsToggle.valueChanged = { [weak self] in
            guard let `self` = self else { return }
            self.toggleChanged(toggle: self.transactionsToggle)
        }
    }

    private func toggleChanged(toggle: UISwitch) {
        if toggle == unlockToggle {
            
            // If the unlock toggle is off, the transactions toggle is forced to off and disabled.
            // i.e., Only allow Touch/Face ID for sending transactions if the user has enabled Touch/Face ID
            // for unlocking the app.
            if !toggle.isOn {
                Store.perform(action: Biometrics.SetIsEnabledForUnlocking(false))
                Store.perform(action: Biometrics.SetIsEnabledForTransactions(false))
            } else {
                if LAContext.canUseBiometrics || E.isSimulator {
                    
                    LAContext.checkUserBiometricsAuthorization(callback: { (result) in
                        if result == .success {
                            Store.perform(action: Biometrics.SetIsEnabledForUnlocking(true))
                        } else {
                            self.unlockToggle.setOn(false, animated: true)
                        }
                    })
                    
                } else {
                    self.presentCantUseBiometricsAlert()
                    self.unlockToggle.setOn(false, animated: true)
                }
            }
            
        } else if toggle == transactionsToggle {
            Store.perform(action: Biometrics.SetIsEnabledForTransactions(toggle.isOn))
        }
    }
    
    private func addFaqButton() {
        let negativePadding = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        negativePadding.width = -16.0
        let faqButton = UIButton.buildFaqButton(articleId: ArticleIds.enableTouchId)
        faqButton.tintColor = .white
        navigationItem.rightBarButtonItems = [negativePadding, UIBarButtonItem(customView: faqButton)]
    }

    fileprivate func presentCantUseBiometricsAlert() {
        let unavailableAlertTitle = LAContext.biometricType() == .face ? S.FaceIDSettings.unavailableAlertTitle : S.TouchIdSettings.unavailableAlertTitle
        let unavailableAlertMessage = LAContext.biometricType() == .face ? S.FaceIDSettings.unavailableAlertMessage : S.TouchIdSettings.unavailableAlertMessage
        
        let alert = UIAlertController(title: unavailableAlertTitle,
                                      message: unavailableAlertMessage,
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: S.Button.cancel, style: .cancel, handler: nil))

        alert.addAction(UIAlertAction(title: S.Button.settings, style: .default, handler: { _ in
            guard let url = URL(string: "App-Prefs:root") else { return }
            UIApplication.shared.open(url)
        }))

        present(alert, animated: true, completion: nil)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
