# This class and related code draws heavily on
# https://github.com/curationexperts/alexandria-v2/blob/master/app/models/time_span.rb
#which is licensed as follows:
#
#This software is Copyright © 2012-2013 The Regents of the University of California. All Rights Reserved.
#
#Permission to copy, modify, and distribute this software and its documentation for educational, research and non-profit purposes, without fee, and without a written agreement is hereby granted, provided that the above copyright notice, this paragraph and the following three paragraphs appear in all copies.
#
#Permission to make commercial use of this software may be obtained by contacting:
#
#Technology Transfer Office 9500 Gilman Drive, Mail Code 0910 University of California La Jolla, CA 92093-0910 (858) 534-5815 invent@ucsd.edu
#
#This software program and documentation are copyrighted by The Regents of the University of California. The software program and documentation are supplied "as is", without any accompanying services from The Regents. The Regents does not warrant that the operation of the program will be uninterrupted or error-free. The end-user understands that the program was developed for research purposes and is advised not to rely exclusively on the program for any reason.
#
#IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES, INCLUDING LOST PROFITS, ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATIONS TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
class TimeSpan < ActiveFedora::Base
  include Sufia::Noid

  type ::RDF::Vocab::EDM.TimeSpan

  property :start, predicate: ::RDF::Vocab::EDM.begin, multiple: false
  property :finish, predicate: ::RDF::Vocab::EDM.end, multiple: false
  property :start_qualifier, predicate: ::RDF::Vocab::CRM.P79_beginning_is_qualified_by, multiple: false
  property :finish_qualifier, predicate: ::RDF::Vocab::CRM.P80_end_is_qualified_by, multiple: false
  property :note, predicate: ::RDF::SKOS.note, multiple: false

  # DACS date qualifiers
  # http://www2.archivists.org/standards/DACS/part_I/chapter_2/4_date
  BEFORE = "before"
  AFTER = "after"
  CENTURY = "century"
  CIRCA = "circa"
  DECADE = "decade"
  UNDATED = "Undated"

  START_QUALIFIERS = [BEFORE, AFTER, CENTURY, CIRCA, DECADE, UNDATED]
  END_QUALIFIERS = [BEFORE, CIRCA]

  def self.start_qualifiers
    START_QUALIFIERS
  end

  def self.end_qualifiers
    END_QUALIFIERS
  end

  def range?
    start.present? && finish.present?
  end

  # TODO: this produces 'circa YYYY - circa YYYY'
  # Return a string for display of this record
  def display_label
    start_string = qualified_date(start, start_qualifier)
    finish_string = qualified_date(finish, finish_qualifier)
    date_string = [start_string, finish_string].compact.join(' - ')
    if note.present?
      date_string << " (#{note})"
    end
    date_string
  end

  def qualified_date(date, qualifier)
    if qualifier == (BEFORE) || qualifier == (AFTER) || qualifier == (CIRCA)
      "#{qualifier} #{date}"
    elsif qualifier ==  DECADE
      "#{date}s (decade)"
    elsif qualifier ==  CENTURY
      "#{date}s (century)"
    # TODO: If it has a date but also says undated, which do we believe?
    elsif qualifier ==  UNDATED
      qualifier
    elsif date.present?
      date
    else
      nil
    end
  end

  # TODO: Validations
  #  - if start qualifier is 'decade' there should be no end or end qualifier. start should be a year ending '0'.
  #  - if start qualifier is 'century' there should be no end or end qualifier. start should be a year ending '00'.
  #  - if start qualifier is 'undated' there should be no start, end, or end qualifier
  #  - if start qualifier is 'before' there should be no end or end qualifier
  #  - if end exists, start must exist
  #  - if end exists, start < end
  #  - if end exists, legal start qualifiers include:
  #    - (none / exact)
  #    - after
  #    - circa
  #  - legal end qualifiers are:
  #    - (none / exact)
  #    - before
  #    - circa

  #  TODO: solr
  #  note 'decade' is a special case
  # Return an array of years, for faceting in Solr.
  def to_a
    if range?
      (start_integer..finish_integer).to_a
    else
      start_integer
    end
  end

  private
    def start_integer
      extract_year(start)
    end

    def finish_integer
      extract_year(finish)
    end

    def extract_year(date)
      date = date.to_s
      if date.blank?
        nil
      elsif /^\d{4}$/ =~ date
        # Date.iso8601 doesn't support YYYY dates
        date.to_i
      else
        Date.iso8601(date).year
      end
    rescue ArgumentError
      raise "Invalid date: #{date.inspect} in #{self.inspect}"
    end
end
