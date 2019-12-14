/// Copyright (c) 2019 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import Combine

class DataManager: NSObject {

  // MARK: - Properties
  static var current: DataManager? {

    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    guard let existingManager = appDelegate.dataManager else {
        // Create and assign new data manager to the AppDelegate

      if let user = Guardpost.current.currentUser {
				let dataManager = DataManager(user: user, persistenceStore: appDelegate.persistenceStore)
        appDelegate.dataManager = dataManager
      } else {
        appDelegate.dataManager = nil
      }

      return appDelegate.dataManager
    }

    return existingManager
  }

  // Persisted informationo
  let domainsMC: DomainsMC
  let categoriesMC: CategoriesMC
  var filters: Filters

  // Content holders
  let inProgressContentVM: InProgressContentVM
  let completedContentVM: CompletedContentVM
  let bookmarkContentMC: BookmarkContentsVM
  let libraryContentsVM: LibraryContentsVM
  
  // Services
  private(set) var progressionsMC: ProgressionsMC?
  private(set) var bookmarksMC: BookmarksMC?
  let downloadsMC: DownloadsMC

  private var domainsSubscriber: AnyCancellable?
  private var categoriesSubsciber: AnyCancellable?

  // MARK: - Initializers
  init(user: UserModel,
       persistenceStore: PersistenceStore) {
    
    self.domainsMC = DomainsMC(user: user,
                               persistenceStore: persistenceStore)

    self.categoriesMC = CategoriesMC(user: user,
                                     persistenceStore: persistenceStore)

    self.filters = Filters()

    self.libraryContentsVM = LibraryContentsVM(user: user,
                                               filters: self.filters)

    self.inProgressContentVM = InProgressContentVM(user: user,
                                                   completionStatus: .inProgress)
    
    self.completedContentVM = CompletedContentVM(user: user,
                                                 completionStatus: .completed)
    
    self.bookmarkContentMC = BookmarkContentsVM(user: user)
    self.downloadsMC = DownloadsMC(user: user)

    super.init()
    createSubscribers()
    loadInitial()
    
    // These two need the dataManager to function, so we're initializing them after we've created it
    bookmarksMC = BookmarksMC(user: user, dataManager: self)
    progressionsMC = ProgressionsMC(user: user, dataManager: self)
  }
  
  func disseminateUpdates(for content: ContentDetailsModel) {
    bookmarkContentMC.updateEntryIfItExists(for: content)
    libraryContentsVM.updateEntryIfItExists(for: content)
    inProgressContentVM.updateEntryIfItExists(for: content)
    completedContentVM.updateEntryIfItExists(for: content)
  }

  private func createSubscribers() {
    domainsSubscriber = domainsMC.objectWillChange
    .sink(receiveValue: { _ in
      self.filters.updatePlatformFilters(for: self.domainsMC.data)
    })

    categoriesSubsciber = categoriesMC.objectWillChange
      .sink(receiveValue: { _ in
        self.filters.updateCategoryFilters(for: self.categoriesMC.data)
      })
  }

  private func loadInitial() {
    domainsMC.populate()
    categoriesMC.populate()
  }
}
