library(DiagrammeR)

grViz(diagram = "digraph flowchart {
  node [fontname = arial, shape = rectangle, fixedsize = true, width = 2.75]
  tab1 [label = '@@1']
  tab2 [label = '@@2']
  tab3 [label = '@@3']
  tab4 [label = '@@4']
  tab5 [label = '@@5']
  tab6 [label = '@@6']
  tab7 [label = '@@7']
  tab8 [label = '@@8']
  tab9 [label = '@@9']
  tab10 [label = '@@10']
  tab11 [label = '@@11']
  tab12 [label = '@@12']
  tab13 [label = '@@13']
  tab14 [label = '@@14']
  tab15 [label = '@@15']
  tab16 [label = '@@16']
  tab17 [label = '@@17']
  tab18 [label = '@@18']
  tab19 [label = '@@19']
  tab20 [label = '@@20']
  tab21 [label = '@@21']
  tab22 [label = '@@22']
  tab23 [label = '@@23']
  tab24 [label = '@@24']
  tab25 [label = '@@25']
  tab26 [label = '@@26']
  
  tab1 -> tab3;
  tab2 -> tab3;
  tab1 -> tab4;
  tab2 -> tab5;
  tab3 -> tab6;
  tab4 -> tab6;
  tab5 -> tab6;
  tab6 -> tab7;
  tab7 -> tab8;
  tab1 -> tab9;
  tab8 -> tab10;
  tab9 -> tab10;
  tab10 -> tab11;
  tab10 -> tab12;
  tab11 -> tab13;
  tab12 -> tab13;
  tab13 -> tab14;
  tab14 -> tab15;
  tab10 -> tab16;
  tab15 -> tab16;
  tab16 -> tab17;
  tab15 -> tab18;
  tab18 -> tab17;
  tab8 -> tab19;
  tab1 -> tab20;
  tab19 -> tab20;
  tab20 -> tab21;
  tab2 -> tab22;
  tab21 -> tab22;
  tab21 -> tab23;
  tab22 -> tab23;
  tab23 -> tab24;
  tab2 -> tab25;
  tab24 -> tab25;
  tab25 -> tab26;
  tab24 -> tab26;
  tab17 -> tab26
  
}
  
  [1]: 'lab_today'
  [2]: 'case_yday'    
  [3]: 'dedup_df'   
  [4]: 'lab_today_info'
  [5]: 'case_yday_info'
  [6]: 'dedup_df_info'
  [7]: 'dedup_df_jw'
  [8]: 'dedup_df_jw_manual'
  [9]: 'lab_today_pos'
  [10]: 'lab_today_pos_nodup'
  [11]: 'dedup_new_df'
  [12]: 'lab_today_pos_nodup_info'
  [13]: 'dedup_new_df_info'
  [14]: 'dedup_new_df_jw'
  [15]: 'dedup_new_df_jw_manual'
  [16]: 'lab_today_pos_nodup_nodup'
  [17]: 'case_today'
  [18]: 'case_today_dedup'
  [19]: 'dedup_df_jw_IDpairs'
  [20]: 'dedup_df_jw_allinfo'
  [21]: 'case_today_newinfo'
  [22]: 'case_today_oldinfo'
  [23]: 'case_today_recon'
  [24]: 'case_yday_update'
  [25]: 'case_yday_noupdate'
  [26]: 'case_latest'
  ")
