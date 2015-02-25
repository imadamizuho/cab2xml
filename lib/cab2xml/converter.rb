require "nokogiri"
require "csv"

module Cab2xml
	class Converter
		attr_accessor :attr_mode, :token_format
		def initialize
			@attr_mode = :attr
			@token_format = :mecab_unidic
		end
		def parse(file)
			@xml, @sen, @senid = nil
			file.set_encoding 'UTF-8'
			file.each_line do |line|
				line.chomp!
				case line
				when ''
					# ignore
				when /^##/
					# comment line
				when /^#!/
					parse_extended_tag line
				else
					parse_cabocha_tag line
				end
			end
			return @xml
		end
		def create_xml(mode)
			# mode = {:corpora|:document}
			@xml = Nokogiri::XML("<#{mode}/>")
			@xml.encoding = 'UTF-8'
			@corpora = @xml.root if mode == :corpora
			@doc = @xml.root if mode == :document
		end
		def add_node(parent, format, data)
			parent << (format % data)
			@last = parent.children.last
			return @last
		end
		def check_namespace(key)
			return unless key =~ /:/
			namespace, key = key.split(':', 2)
			@namespaces ||= {}
			return if @namespaces[namespace]
			@namespaces[namespace] = true
			@doc.add_namespace namespace, 'http://www.ninjal.ac.jp/corpus_center/bccwj/' + namespace
		end
		def parse_extended_tag(line)
			null, label, *data = CSV.parse_line(line, :col_sep => "\s")
			data.map!{|item| item.encode(:xml => :text)}
			case label
			when 'DOCID'
				create_xml(:corpora) unless @xml
				format = '<DOCID id=%d>%s</DOCID>'
				@docid = add_node(@corpora, format, data)
			when 'SENTENCETAGID'
				format = '<SENTENCETAGID id=%d>%s</SENTENCETAGID>'
				@sentencetagid = add_node(@corpora, format, data)
			when 'DOC'
				format = '<document id="%d"/>'
				@doc = add_node(@corpora, format, data)
				@senid = 0
			when 'ATTR'
				case @attr_mode
				when :node
					format = '<ATTR Key="%s" Value="%s"/>'
					@attr = add_node(@last, format, data)
				when :attr
					key, value = data
					check_namespace key
					@last[key] = value
				end
			when 'SEGMENT'
				format = '<SEGMENT TagName="%s" StartGPos="%s" EndGPos="%s" Comments="%s"/>'
				@seg = add_node(@doc, format, data)
			when 'SEGMENT_S'
				format = '<SEGMENT_S TagName="%s" StartLPos="%s" EndLPos="%s" Comments="%s"/>'
				@seg = add_node(@sen, format, data)
			when 'LINK'
				format = '<LINK TagName="%s" FromSegNo="%s" EndSegNo="%s" Comments="%s"/>'
				@link = add_node(@doc, format, data)
			when 'LINK_S'
				format = '<LINK_S TagName="%s" FromSegSNo="%s" EndSegSNo="%s" Comments="%s"/>'
				@link = add_node(@sen, format, data)
			when 'GROUP'
				format = '<GROUP TagName="%s" SegNo="%s" Comments="%s"/>'
				data = [data[0], data[1..-2].join(','), data[-1]]
				@group = add_node(@doc, format, data)
			when 'GROUP_S'
				format = '<GROUP_S TagName="%s" SegSNo="%s" Comments="%s"/>'
				data = [data[0], data[1..-2].join(','), data[-1]]
				@group = add_node(@sen, format, data)
			end
		end
		def parse_cabocha_tag(line)
			case line
			when /^\*/
				create_xml(:document) unless @xml
				unless @sen
					@sen = add_node(@doc, '<sentence id="%d"/>', @senid ||= 0)
					@senid += 1
					@tokid = 0
				end
				null, id, dep, headfunc, score = line.split(' ')
				link, rel = dep[0..-2], dep[-1]
				head, func = headfunc.split('/')
				data = [id, link, rel, head, func, score]
				format = '<chunk id="%d" link="%d" rel="%s" head="%d" func="%d" score="%s"/>'
				@chunk = add_node(@sen, format, data)
			when 'EOS'
				@sen = nil
			else
				case token_format
				when :chasen
					data = line.split(/\s/)
					data = [@tokid, *data[1..5], data[0]]
					format = '<tok id="%d" read="%s" base="%s" pos="%s" cype="%s" cform="%s">%s</tok>'
					@tok = add_node(@chunk, format, data)
					@tokid += 1
				when :mecab_unidic
					text, data = line.split(/\s/, 2)
					data = data.split(',').map{|item| item == '*' ? nil : item }
					pos = data[0, 4].compact.join('-')
					ctype, cform, lemmaForm, lemma = data[4, 4]
					data = [@tokid, pos, ctype, cform, lemmaForm, lemma, text]
					format = '<tok id="%d" pos="%s" cype="%s" cform="%s" lemmaForm="%s" lemma="%s">%s</tok>'
					@tok = add_node(@chunk, format, data)
					@tokid += 1
				end
			end
		end
	end
end
