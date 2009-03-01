
# see: http://broadcast.oreilly.com/2009/02/merb-mind-maps.html

require File.join( File.dirname(__FILE__), 'spec_helper' )
require 'assert2/xpath'

Spec::Runner.configure do |c|
  c.include Test::Unit::Assertions
end

describe MindMap do

  setup do
    FixtureDependencies.load(:posts)
    FixtureDependencies.load(:tags)
       #  note that all specs will still work
  end  #  even if we add new fixtures

  def load(model, symbols)
    symbols.map!{|symbol| :"#{model}__#{symbol}" }
    return FixtureDependencies.load(*symbols)
  end

  def posts(*symbols);  load(:post, symbols);  end
  def tags(*symbols);   load(:tag,  symbols);  end

  it 'should rate two posts by affinity' do
    map  = MindMap.new
    jam  = posts(:Jammin)
    sard = posts(:Sardonicus)
    lith = posts(:Lithium)
    oryx = posts(:Oryx_vs_Crake)
    map.affinity(jam, sard).should == 3  #  reggae, back_beat, & music
    map.affinity(jam, lith).should == 1  #  music
    map.affinity(jam, oryx).should == 0  #  a book!
  end

  it 'should produce elements of arrays sortable by affinity' do
    jam  = posts(:Jammin)
    map  = MindMap.new(jam)
    one  = posts(:One_Step_Beyond)
    joan = posts(:Joan_Crawford_Has_Risen)
    oryx = posts(:Oryx_vs_Crake)
    jam_to_one  = map.affinity_edge(jam,  one)
    jam_to_joan = map.affinity_edge(jam, joan)
    joan_to_one = map.affinity_edge(joan, one)
    jam_to_oryx = map.affinity_edge(jam, oryx)

                       #   +----- 0 == this edge links to the current Post
                       #   |   +-- "cost" of this edge
                       #   |   |   +-- Posts in this edge
                       #   v   v   v
    jam_to_one .should == [0, -2, jam,  one ]
    jam_to_joan.should == [0, -1, jam,  joan]
    joan_to_one.should == [1, -1, joan, one ]
    jam_to_oryx.should == [0,  0, jam,  oryx]
  end  #  sorting an array of those will find the maximum value tree

  it 'should produce elements of arrays sortable by affinity' do
    jam   = posts(:Jammin)
    map   = MindMap.new(jam)
    one   = posts(:One_Step_Beyond)
    joan  = posts(:Joan_Crawford_Has_Risen)
    oryx  = posts(:Oryx_vs_Crake)  #  the <em>vs<em> is an inside joke... (-:
    edges = map.affinity_edges
    edges.length.should == edges.uniq.length
    assert{ [0, -2, jam,  one ].in?(edges) }
    assert{ [0, -1, jam,  joan].in?(edges) }
    pairs = edges.map{|c,a,f,t| [f,t]}
    assert{  [joan, one ].in?(pairs) }
    assert{ ![jam,  oryx].in?(pairs) }  #  no edge!
    assert{ ![one,  jam ].in?(pairs) }  #  not unique!
    assert{ ![joan, jam ].in?(pairs) }
    assert{ ![one,  joan].in?(pairs) }
  end  #  note that an "assert not" must relax more than an assert!

  class ::Post
    def inspect;  "<#{title}>";  end
  end  #  this makes diagnostics easier to understand

  it 'should produce elements of arrays sorted by affinity' do
    jam, sard, one, joan = posts( :Jammin, :Sardonicus, :One_Step_Beyond,
                                  :Joan_Crawford_Has_Risen )
    map   = MindMap.new(jam)
    edges = map.sorted_affinity_edges
    jam_to_sard  = edges.index([0, -3, jam,  sard])  #  both are reggae
    jam_to_one   = edges.index([1, -2, jam,  one ])  #  both have a back beat
    jam_to_joan  = edges.index([1, -1, jam,  joan])  #  both are music
    joan_to_sard = edges.index([1, -2, joan, sard])  #  both are progressive
    jam_to_sard .should == 0
    jam_to_sard .should < jam_to_one
    jam_to_one  .should < jam_to_joan
    joan_to_sard.should < jam_to_joan
    edges.should == edges.sort
  end

  it 'should cull low-value Posts and edges' do
    jam, sard, one, joan = posts( :Jammin, :Sardonicus, 
                                  :One_Step_Beyond,
                                  :Joan_Crawford_Has_Risen )
    map = MindMap.new(jam)
    pairs = map.cull
    assert{  [jam, sard].in?(pairs) }  #  essentially the trunk!
    assert{ ![jam, joan].in?(pairs) }  #  because joan is closer to other nodes
    assert{ ![one, sard].in?(pairs) }  #  to avoid a cycle with Jammin...
  end

  it "should create a graph containing the current Post's title" do
    post = posts(:Jammin)
    map = MindMap.new(post)
    dot = map.to_dot
    dot.should match(/graph mind_map \{/)
    dot.should match(/post_#{post.id}.*label = .#{post.title}/)
  end

  it 'should push related Posts into graph nodes' do
    suspects = posts( :Jammin, :Sardonicus, :One_Step_Beyond,
                      :Joan_Crawford_Has_Risen, :Lithium )

    dot = MindMap.new(suspects.first).to_dot

    suspects.each do |post|
      dot.should match(/post_#{ post.id }.*label.*#{ post.title }/)
    end
    
    dot.should_not match(/Oryx and Crake/)
  end

  it 'should link Posts by maximum affinity' do
    jam, sard = posts(:Jammin, :Sardonicus)
    dot = MindMap.new(jam).to_dot
    dot.should match(/post_#{ jam.id } -- post_#{ sard.id }/)
  end

  it 'should generate SVG' do
    posts = posts(:C30_C60_C90_Go, :Lithium)
    image = MindMap.new(posts.first).to_image(:svg)
    path  = Pathname.new(Merb.root) + "public" + image
    assert_xhtml path.read
    
    assert do
      xpath :"g[ @class = 'edge' ]/title[ 
                    contains(., 'post_#{posts.first.id}') and
                    contains(., 'post_#{posts.last.id}') ]"
    end
  end

  it 'should decorate the Post page with a mind map' do
    jam_id = posts(:Jammin).id
    @response = request("/posts/#{jam_id}")
    assert_xhtml @response.body

    xpath :div, :class => :post do
      xpath :div, :style => 'clear:right; float:right;' do
        xpath :img, :src => "/images/post_#{jam_id}.png"
      end
    end
  end

end

