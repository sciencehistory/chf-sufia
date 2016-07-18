# Generated via
#  `rails generate curation_concerns:work GenericWork`
require 'rails_helper'

describe CurationConcerns::GenericWorksController do

  let (:user) { FactoryGirl.create(:depositor) }
  let (:work) { GenericWork.new(title: ['Blueberries for Sal']) }

  before do
    sign_in user
    work.apply_depositor_metadata(user.user_key)
    work.save!
  end

  describe "#show" do
    context "with a public user" do
      it "uses our presenter" do
        get :show, id: work.id
        expect(assigns(:presenter)).to be_kind_of CurationConcerns::GenericWorkShowPresenter
        expect(assigns(:presenter)).to be_kind_of Sufia::WorkShowPresenter
      end
    end
  end

  describe "#edit" do
    it "includes genre" do
      get :edit, id: work.id
      expect(response).to be_successful
      expect(assigns['form'].genre_string).to eq [""]
    end
  end

  describe "update" do
    it "changes to resource_type are independent from changes to genre" do
      patch :update, id: work, generic_work: {
        resource_type: ['Image']
      }
      work.reload
      expect(work.resource_type).to eq ['Image']
      # why is it an empty string in the form but an empty array here??
      #   - the model doesn't save empty strings as values
      expect(work.genre_string).to eq []

      patch :update, id: work, generic_work: {
        genre_string: ['Photographs']
      }
      work.reload
      expect(work.resource_type).to eq ['Image']
      expect(work.genre_string).to eq ['Photographs']
    end

    context "dates" do
      let(:ts_attributes) do
        {
          start: "2014",
          start_qualifier: "",
          finish: "",
          finish_qualifier: "",
          note: "",
        }
      end
      let(:time_span) { DateOfWork.new(ts_attributes) }

      context "date" do
        context "creating a new date" do
          context "date data is provided" do
            it "persists the nested object" do
              patch :update, id: work, generic_work: {
                date_of_work_attributes: { "0" => ts_attributes },
                resource_type: ['Image']
              }

              work.reload
              pub_date = work.date_of_work.first

              expect(work.date_of_work.count).to eq(1)
              expect(pub_date.start).to eq("2014")
              expect(pub_date).to be_persisted
            end
          end
          context "two sets of date data are provided" do
            let(:ts_attributes2) { ts_attributes.clone }
            before do
              ts_attributes2[:start] = '1999'
              patch :update, id: work, generic_work: {
                date_of_work_attributes: { "0" => ts_attributes, "1" => ts_attributes2 },
                resource_type: ['Image']
              }
              work.reload
            end

            it "persists the nested objects" do
              pub_dates = work.date_of_work

              expect(work.date_of_work.count).to eq(2)
              expect(pub_dates[0].start).to eq("2014")
              expect(pub_dates[1].start).to eq("1999")
              expect(pub_dates[0]).to be_persisted
              expect(pub_dates[1]).to be_persisted
            end

          end
          context "date data is not provided" do
            it "does not persist a nested object" do
              ts_attributes[:start] = ""
              patch :update, id: work, generic_work: {
                date_of_work_attributes: { "0" => ts_attributes },
                resource_type: ['Image']
              }
              work.reload
              pub_date = work.date_of_work.first
              expect(work.date_of_work.count).to eq(0)
              expect(DateOfWork.all.count).to eq 0
            end
          end
        end

        context "when the date already exists" do
          before do
            time_span.save!
            work.date_of_work << time_span
            work.save!
          end

          it "allows deletion of the existing timespan" do
            work.reload
            expect(work.date_of_work.count).to eq(1)

            patch :update, id: work, generic_work: {
              date_of_work_attributes: {
                "0" => { id: time_span.id, _destroy: "true" }
              }
            }
            work.reload
            expect(work.date_of_work.count).to eq(0)
            #TODO: if we want the TimeSpan to be deleted entirely,
            #     we may need to define a new association in activefedora.
            #     see irc conversation 7/8/2015
            #expect(TimeSpan.all.count).to eq 0
          end
          # just documenting behavior here.. object is not reused.
          it "Creates a new TimeSpan object with same data" do
            work2 = GenericWork.new(title: ['Sal and Baby Bear'])
            work2.apply_depositor_metadata(user.user_key)
            work2.save!
            patch :update, id: work2, generic_work: {
              date_of_work_attributes: { "0" => ts_attributes },
            }
            expect(DateOfWork.all.count).to eq 2
          end

          it "allows updating the existing timespan" do
            patch :update, id: work, generic_work: {
              date_of_work_attributes: {
                "0" => ts_attributes.merge(id: time_span.id, start: "1337", start_qualifier: "circa")
              },
            }

            work.reload
            expect(work.date_of_work.count).to eq(1)
            pub_date = work.date_of_work.first

            expect(pub_date.id).to eq(time_span.id)
            expect(pub_date.start).to eq("1337")
            expect(pub_date.start_qualifier).to eq("circa")
          end

          it "allows updating the existing timespan while adding a 2nd timespan" do
            patch :update, id: work, generic_work: {
              date_of_work_attributes: {
                "0" => ts_attributes.merge(id: time_span.id, start: "1337", start_qualifier: "circa"),
                "1" => ts_attributes.merge(start: "5678")
              },
            }

            work.reload
            expect(work.date_of_work.count).to eq(2)
            pub_date = work.date_of_work.first

            expect(pub_date.id).to eq(time_span.id)
            expect(pub_date.start).to eq("1337")
            expect(pub_date.start_qualifier).to eq("circa")

            pub_date = work.date_of_work.second
            expect(pub_date.start).to eq("5678")
            expect(pub_date.start_qualifier).to eq("")
          end

        end
      end
    end  # context dates


    context "inscriptions" do
      let(:i_attributes) do
        {
          location: "mars",
          text: "welcome to mars"
        }
      end
      let(:inscrip) { Inscription.new(i_attributes) }

      context "creating a new inscription" do
        it "persists the nested object" do
          patch :update, id: work, generic_work: {
            inscription_attributes: { "0" => i_attributes },
            resource_type: ['Image']
          }

          work.reload
          insc = work.inscription.first

          expect(work.inscription.count).to eq(1)
          expect(insc.location).to eq("mars")
          expect(insc).to be_persisted
        end
        context "two sets of date data are provided" do
          let(:i_attributes2) { i_attributes.clone }
          before do
            i_attributes2[:location] = 'pluto'
            patch :update, id: work, generic_work: {
              inscription_attributes: { "0" => i_attributes, "1" => i_attributes2 },
              resource_type: ['Image']
            }
            work.reload
          end

          it "persists the nested objects" do
            insc = work.inscription

            expect(work.inscription.count).to eq(2)
            expect(insc[0].location).to eq("mars")
            expect(insc[1].location).to eq("pluto")
            expect(insc[0]).to be_persisted
            expect(insc[1]).to be_persisted
          end
        end

        context "inscription data is not provided" do
          it "does not persist a nested object" do
            i_attributes[:location] = ""
            i_attributes[:text] = ""
            patch :update, id: work, generic_work: {
              inscription_attributes: { "0" => i_attributes },
              resource_type: ['Image']
            }
            work.reload
            insc = work.inscription.first
            expect(work.inscription.count).to eq(0)
            expect(Inscription.all.count).to eq 0
          end
        end
      end

      context "updating an existing inscription" do
        before do
          inscrip.save!
          work.inscription << inscrip
          work.save!
        end

        it "allows deletion of the existing timespan" do
          work.reload
          expect(work.inscription.count).to eq(1)

          patch :update, id: work, generic_work: {
            inscription_attributes: {
              "0" => { id: inscrip.id, _destroy: "true" }
            }
          }
          work.reload
          expect(work.inscription.count).to eq(0)
          #TODO: if we want the Inscription to be deleted entirely,
          #     we may need to define a new association in activefedora.
          #     see irc conversation 7/8/2015
          #expect(Inscription.all.count).to eq 0
        end
        # just documenting behavior here.. object is not reused.
        it "Creates a new Inscription object with same data" do
          work2 = GenericWork.new(title: ['Sal and Baby Bear'])
          work2.apply_depositor_metadata(user.user_key)
          work2.save!
          patch :update, id: work2, generic_work: {
            inscription_attributes: { "0" => i_attributes },
          }
          expect(Inscription.all.count).to eq 2
        end

        it "allows updating the existing inscription" do
          patch :update, id: work, generic_work: {
            inscription_attributes: {
              "0" => i_attributes.merge(id: inscrip.id, location: "earth")
            },
          }

          work.reload
          expect(work.inscription.count).to eq(1)
          insc = work.inscription.first

          expect(insc.id).to eq(inscrip.id)
          expect(insc.location).to eq("earth")
          expect(insc.text).to eq("welcome to mars")
        end

        it "allows updating the existing inscription while adding a 2nd inscription" do
          patch :update, id: work, generic_work: {
            inscription_attributes: {
              "0" => i_attributes.merge(id: inscrip.id, location: "earth", text: "blue planet"),
              "1" => i_attributes.merge(location: "jupiter", text: "")
            },
          }

          work.reload
          expect(work.inscription.count).to eq(2)
          insc = work.inscription.first

          expect(insc.id).to eq(inscrip.id)
          expect(insc.location).to eq("earth")
          expect(insc.text).to eq("blue planet")

          insc = work.inscription.second
          expect(insc.location).to eq("jupiter")
          expect(insc.text).to eq("")
        end


      end
    end  # context inscriptions

    context "additional credits" do
      let(:ac_attributes) do
        {
          role: "photographer",
          name: "bears"
        }
      end
      let(:additional_c) { Credit.new(ac_attributes) }

      context "creating a new additional credit" do
        it "persists the nested object" do
          patch :update, id: work, generic_work: {
            additional_credit_attributes: { "0" => ac_attributes },
            resource_type: ['Image']
          }

          work.reload
          ac = work.additional_credit.first

          expect(work.additional_credit.count).to eq(1)
          expect(ac.role).to eq("photographer")
          expect(ac).to be_persisted
        end
        context "two sets of date data are provided" do
          let(:ac_attributes2) { ac_attributes.clone }
          before do
            ac_attributes2[:name] = 'goldilocks'
            patch :update, id: work, generic_work: {
              additional_credit_attributes: { "0" => ac_attributes, "1" => ac_attributes2 },
              resource_type: ['Image']
            }
            work.reload
          end

          it "persists the nested objects" do
            ac = work.additional_credit

            expect(work.additional_credit.count).to eq(2)
            expect(ac[0].name).to eq("bears")
            expect(ac[1].name).to eq("goldilocks")
            expect(ac[0]).to be_persisted
            expect(ac[1]).to be_persisted
          end
        end

        context "additional credit data is not provided" do
          it "does not persist a nested object" do
            ac_attributes[:role] = ""
            ac_attributes[:name] = ""
            patch :update, id: work, generic_work: {
              additional_credit_attributes: { "0" => ac_attributes },
              resource_type: ['Image']
            }
            work.reload
            ac = work.additional_credit.first
            expect(work.additional_credit.count).to eq(0)
            expect(Credit.all.count).to eq 0
          end
        end
      end

      context "updating an existing additional credit" do
        before do
          additional_c.save!
          work.additional_credit << additional_c
          work.save!
        end

        it "allows deletion of the existing timespan" do
          work.reload
          expect(work.additional_credit.count).to eq(1)

          patch :update, id: work, generic_work: {
            additional_credit_attributes: {
              "0" => { id: additional_c.id, _destroy: "true" }
            }
          }
          work.reload
          expect(work.additional_credit.count).to eq(0)
          #TODO: if we want the additional credit to be deleted entirely,
          #     we may need to define a new association in activefedora.
          #     see irc conversation 7/8/2015
          #expect(Credit.all.count).to eq 0
        end
        # just documenting behavior here.. object is not reused.
        it "Creates a new additional credit object with same data" do
          work2 = GenericWork.new(title: ['Sal and Baby Bear'])
          work2.apply_depositor_metadata(user.user_key)
          work2.save!
          patch :update, id: work2, generic_work: {
            additional_credit_attributes: { "0" => ac_attributes },
          }
          expect(Credit.all.count).to eq 2
        end

        it "allows updating the existing additional credit" do
          patch :update, id: work, generic_work: {
            additional_credit_attributes: {
              "0" => ac_attributes.merge(id: additional_c.id, name: "3 bears")
            },
          }

          work.reload
          expect(work.additional_credit.count).to eq(1)
          ac = work.additional_credit.first

          expect(ac.id).to eq(additional_c.id)
          expect(ac.role).to eq("photographer")
          expect(ac.name).to eq("3 bears")
        end

        it "allows updating the existing additional credit while adding a 2nd additional credit" do
          patch :update, id: work, generic_work: {
            additional_credit_attributes: {
              "0" => ac_attributes.merge(id: additional_c.id, role: "photographer", name: "3 bears"),
              "1" => ac_attributes.merge(role: "photographer", name: "goldilocks")
            },
          }

          work.reload
          expect(work.additional_credit.count).to eq(2)
          ac = work.additional_credit.first

          expect(ac.id).to eq(additional_c.id)
          expect(ac.role).to eq("photographer")
          expect(ac.name).to eq("3 bears")

          ac = work.additional_credit.second
          expect(ac.role).to eq("photographer")
          expect(ac.name).to eq("goldilocks")
        end


      end
    end  # context additional_credits


    context 'parsed fields' do
      it 'turns box, etc into coded string' do
        patch :update, id: work, generic_work: {
          box: '2',
          folder: '3',
          page: '14',
        }

        work.reload
        expect(work.physical_container).to eq 'b2|f3|g14'
      end

      it 'turns external ids into coded strings' do
        patch :update, id: work, generic_work: {
          object_external_id: ['2008.043.002']
        }

        work.reload
        expect(work.identifier).to eq ['object-2008.043.002']
      end
    end # context parsed fields
  end # update

end
