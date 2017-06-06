# We're actually overriding from the sufia-set Sufia::FileSetPresenter, to our
# own. to_prepare seems necessary to make it stick in dev.
CurationConcerns::MemberPresenterFactory.file_presenter_class = CHF::FileSetPresenter

# And we also need to set the work_presenter_class, so it comes back from
# GenericWork#member_presenters. This is actually a custom CHF one despite the
# namespace.
CurationConcerns::MemberPresenterFactory.work_presenter_class = CurationConcerns::GenericWorkShowPresenter
