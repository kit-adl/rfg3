package provide odfi::rfg::generator::html      3.0.0
package require odfi::rfg                       3.0.0
package require odfi::ewww::html                2.0.0
package require http 2.8.8

namespace eval odfi::rfg::generator::html {

    variable location [file dirname [info script]]

    odfi::language::Language default {


        :HTMLGenerator {
#            +exportTo ::odfi::rfg::Group html


            +method toHTML folder {

                ## Prepare Output Folder 
                file mkdir $folder

                ## set main Name 
                set rfGroup [current object]

                
                ## Prepare base HTML
                
                set html [odfi::ewww::html::html {
                    :head {
                        :bootstrap:localUse $folder
 
                        #odfi::ewww::html::bootstrap::httpcopy http://raw.githubusercontent.com/Semantic-Org/Semantic-UI-CSS/master/semantic.min.js  $folder/semantic.min.js
                        #odfi::ewww::html::bootstrap::httpcopy http://raw.githubusercontent.com/Semantic-Org/Semantic-UI-CSS/master/semantic.min.css $folder/semantic.min.css
                        #file copy -force ${odfi::rfg::generator::html::location}/semantic.min.js $folder/semantic.min.js
                        #file copy -force ${odfi::rfg::generator::html::location}/semantic.min.css $folder/semantic.min.css
                        
                        catch {file copy -force ${::odfi::rfg::generator::html::location}/semantic-ui $folder}
                        
                        :javascript jquery-2.1.4.min.js 
                        :javascript semantic-ui/semantic.min.js 
                        :stylesheet semantic-ui/semantic.min.css
                       


                    }
                    :body {
                        :bootstrap:pageHeader [$rfGroup name get] {

                        }
                    }
                }]

                
                set body [$html child 1]

                ## Create Tabs 
                #####################
                $body div {

                    ## Tab List
                    set tabHeaders [:ul {

                        :@ role tablist
                        :class nav nav-tabs

                        set tid 0
                        foreach {id text} {table-view "Table View" tree-view "Tree View"} {
                            :li {
                                :@ role presentation
                                if {$tid==0} {
                                    incr tid
                                    :class active 
                                }
                                
                                :a $text #$id {
                                    :@* aria-controls=$id role=tab data-toggle=tab
                                   # :text $text
                                }
                            
                            }
                        }
                        
                    } ]

                    ## Tabs Content 
                    set tabDivs [:div {
                        :class tab-content

                        ## Map to HTML Table 
                        ############################
                        :div {

                            :@ role tabpanel
                            :id table-view
                            :class tab-pane active


                            
                            set table [[:div {

                                :h2 "Table View" 
                                :bootstrap:table {

                                    :column "Name" {

                                    }
                                    :column "Description" {

                                    }

                                    :column "Address" {

                                    }
                                }

                                
                            }] child 1]

                            #set tbody [$table shade odfi::ewww::html::Tbody child 0]

                            #:map -root $table 
                            $rfGroup walkDepthFirstPreorder {

                                if {[$node isClass odfi::rfg::Register]} {

                                    $table tr {
                                        :td {
                                            :text [$node formatHierarchyString {$it name get} /]/[$node name get]
                                        }

                                        :td {
                                            :text [$node description get]
                                        }

                                        :td {
                                            :text 0x[format "%x" [$node getAttribute ::odfi::rfg::address absolute 0]]
                                        }
                                    }

                                } elseif {[$node isClass odfi::rfg::Field]} {

                                    $table tr {
                                        :td {
                                            :text [$node formatHierarchyString {$it name get} /].[$node name get]
                                        }

                                        :td {
                                            :text [$node description get]
                                        }

                                        :td {

                                        }
                                    }
                                }
                                return true
                            }
                            ## EOF Map to table

                            

                        }
                        ## EOF Table View 

                        ## Map to HTML Tree
                        #############################
                        :div {

                            :@ role tabpanel
                            :id tree-view
                            :class tab-pane

                            
                            :div {
                                :h2 "Tree View"

                                ## Filter 
                                :div {
                                    :input {
                                        :@ placeHolder "Filter"
                                    }
                                }
                                ## View 
                                :div {
                                    :@ class "ui list"

                                    $rfGroup map -root [current object] {

                                        #puts "Map on node [$node name get]"
                                        
                                        if {[$node isClass odfi::rfg::Register]} {

                                            return [[[$parent div {
                                                :@ class "item"
                                                :i {
                                                    :@ class "ellipsis horizontal icon"
                                                }
                                                ## Content Div 
                                                :div {
                                                    :@ class "content"
                                                    :div {
                                                        :@ class "header"
                                                        :text "[$node name get]"
                                                    }
                                                    :div {
                                                        :@ class "description"
                                                        :text "[$node description get]"
                                                    }
                                                    :div {
                                                        :@ class "list"
                                                    }
                                                    
                                                }
                                            }] lastChild] lastChild]

                                        } elseif {[$node isClass odfi::rfg::Field]} {

                                            return [[$parent div {
                                                :@ class "item"
                                                :i {
                                                    :@ class "level up icon"
                                                }
                                                :div {
                                                    :@ class "content"
                                                    :div {
                                                        :@ class "header"
                                                        :text "[$node name get]"
                                                    }
                                                    :div {
                                                        :@ class "description"
                                                        :text "[$node description get]"
                                                    }
                                                    
                                                }
                                            }] lastChild]

                                        } elseif {[$node isClass odfi::rfg::Group]} {

                                            return [[[$parent div {
                                                :@ class "item"
                                                :i {
                                                    :@ class "ellipsis vertical icon"
                                                }
                                                :div {
                                                    :@ class "content"
                                                    :div {
                                                        :@ class "header"
                                                        :text "[$node name get]"
                                                    }
                                                    :div {
                                                        :@ class "description"
                                                        :text "[$node description get]"
                                                    }
                                                    :div {
                                                        :@ class "list"
                                                    }
                                                    
                                                }
                                            }] lastChild] lastChild]

                                        }


                                    }
                                }
                            }
                            ## EOF Map to tree


                        }
                        ## EOF Tree View



                    }]
                    ## EOF Tab divs 


                    ## Extra Special Documentations
                    ###################
                    $rfGroup walkDepthFirstPreorder {

                        if {[llength [$node info lookup methods html:doc]]>0} {
                            set baseReg $node
                            set resultNode [$node html:doc]
                            if {[odfi::common::isClass $resultNode ::odfi::ewww::html::HTMLNode]} {

                                puts "Found a documentation to Add"

                                ## Get ID 
                                if {![$resultNode hasAttribute id]} {
                                    error "Produced HTML Documentation node must have an id"
                                }


                                ## Add A tab header 
                                $tabHeaders li {
                                    :@ role presentation
                                
                                    
                                    :a [$baseReg name get] #[$resultNode getAttribute id]-tab {
                                        :@* aria-controls=[$resultNode getAttribute id]-tab role=tab data-toggle=tab
                                       # :text $text
                                    }
                                
                                }

                                ## Add A tab content 
                                $tabDivs div {
                                    :@ role tabpanel
                                    :id [$resultNode getAttribute id]-tab
                                    :class tab-pane



                                    :addChild $resultNode
                                }


                            }

                        }
                        
                    }
                    ## EOF Extra Doc Walk

                }
                ## EOF Tab Pane 

                

                ## Write out 
                $html toString $folder/[:name get].html
            }
        }

    }

    ::odfi::rfg::Group domain-mixins add odfi::rfg::generator::html::HTMLGenerator -prefix html

}
