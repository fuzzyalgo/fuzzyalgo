//+------------------------------------------------------------------+
//|                                                   RingBuffer.mqh |
//|                                 Copyright 2016, Vasiliy Sokolov. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, Vasiliy Sokolov."
#property link      "http://www.mql5.com"
//+------------------------------------------------------------------+
//| struct ring buffer                                               |
//+------------------------------------------------------------------+
struct SRiBuffStruct 
{
    datetime dt;
    double open;
    double high;
    double low;
    double close;
};

class CRiBuffStruct
{
private:
   bool           m_full_buff;
   int            m_max_total;
   int            m_head_index;
   int            m_period;
   SRiBuffStruct  m_buffer[];
  
protected:
   virtual void   OnAddValue(SRiBuffStruct& value);
   virtual void   OnRemoveValue(SRiBuffStruct& value);
   virtual void   OnChangeValue(int index, SRiBuffStruct& prev_value, SRiBuffStruct& new_value);
   virtual void   OnChangeArray(void);
   virtual void   OnSetMaxTotal(int max_total);
   int            ToRealInd(int index);
public:
                  CRiBuffStruct(void);
   void           AddValue(SRiBuffStruct& value);
   void           ChangeValue(int index, SRiBuffStruct& new_value);
   SRiBuffStruct  GetValue(int index);
   int            GetTotal(void);
   int            GetMaxTotal(void);
   void           SetMaxTotal(int max_total);
   void           ToArray(SRiBuffStruct& array[]);
   int            GetPeriod(void);
   void           SetPeriod(int period);
};
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CRiBuffStruct::CRiBuffStruct(void) :   m_full_buff(false),
                                 m_head_index(-1),
                                 m_max_total(0),
                                 m_period(0)
{
}
//+------------------------------------------------------------------+
//| Called when a new value is received                              |
//+------------------------------------------------------------------+
void CRiBuffStruct::OnAddValue(SRiBuffStruct& value)
{
}
//+------------------------------------------------------------------+
//| Called when an old value is removed                              |
//+------------------------------------------------------------------+
void CRiBuffStruct::OnRemoveValue(SRiBuffStruct& value)
{
}
//+------------------------------------------------------------------+
//| Called when an old value is changed                              |
//+------------------------------------------------------------------+
void CRiBuffStruct::OnChangeValue(int index,SRiBuffStruct& prev_value,SRiBuffStruct& new_value)
{
}
//+------------------------------------------------------------------+
//| Called if the entire array should be counted                     |
//+------------------------------------------------------------------+
void CRiBuffStruct::OnChangeArray(void)
{
}
//+------------------------------------------------------------------+
//| Called when changing the number of elements in the buffer        |
//+------------------------------------------------------------------+
void CRiBuffStruct::OnSetMaxTotal(int max_total)
{
}

//+------------------------------------------------------------------+
//| SetPeriod(int period)
//+------------------------------------------------------------------+
void CRiBuffStruct::SetPeriod(int period)
{
    m_period = period;
}
//+------------------------------------------------------------------+
//| 
//+------------------------------------------------------------------+
int CRiBuffStruct::GetPeriod(void)
{
   return m_period;
}


//+------------------------------------------------------------------+
//| Set the new size of the ring buffer                              |
//+------------------------------------------------------------------+
void CRiBuffStruct::SetMaxTotal(int max_total)
{
   if(ArraySize(m_buffer) == max_total)
      return;
   m_max_total = ArrayResize(m_buffer, max_total);
   OnSetMaxTotal(m_max_total);
}
//+------------------------------------------------------------------+
//| Get the actual ring buffer size                                  |
//+------------------------------------------------------------------+
int CRiBuffStruct::GetMaxTotal(void)
{
   return m_max_total;
}
//+------------------------------------------------------------------+
//| Get the index value                                              |
//+------------------------------------------------------------------+
SRiBuffStruct CRiBuffStruct::GetValue(int index)
{
    int idx = ToRealInd(index);
    if( (idx < m_max_total) && ( 0 <= idx) )
        return m_buffer[idx];
    else
        return m_buffer[0]; 
        
}
//+------------------------------------------------------------------+
//| Get the total number of elements                                 |
//+------------------------------------------------------------------+
int CRiBuffStruct::GetTotal(void)
{
    if(m_full_buff)
    {
        return m_max_total;
    }
    return m_head_index+1;
}
//+------------------------------------------------------------------+
//| Add a new value to the ring buffer                               |
//+------------------------------------------------------------------+
void CRiBuffStruct::AddValue(SRiBuffStruct& value)
{
   if(++m_head_index == m_max_total)
   {
      m_head_index = 0;
      m_full_buff = true;
   }  
   SRiBuffStruct last_value;
   if(m_full_buff)
   {
      last_value = m_buffer[m_head_index];
   }
   m_buffer[m_head_index] = value;
   OnAddValue(value);
   if(m_full_buff)
   {
      OnRemoveValue(last_value);
   }
   OnChangeArray();
}
//+------------------------------------------------------------------+
//| Replace the previously added value with the new one              |
//+------------------------------------------------------------------+
void CRiBuffStruct::ChangeValue(int index, SRiBuffStruct& value)
{
   int r_index = ToRealInd(index);
   SRiBuffStruct prev_value = m_buffer[r_index];
   m_buffer[r_index] = value;
   OnChangeValue(index, prev_value, value);
   OnChangeArray();
}
//+------------------------------------------------------------------+
//| Convert the virtual index into a real one                        |
//+------------------------------------------------------------------+
int CRiBuffStruct::ToRealInd(int index)
{
   if(index >= GetTotal() || index < 0)
      return m_max_total;
   if(!m_full_buff)
      return index;
   int delta = (m_max_total-1) - m_head_index;
   if(index < delta)
      return m_max_total + (index - delta);
   return index - delta;
}
//+------------------------------------------------------------------+
//| Get the array of values                                          |
//+------------------------------------------------------------------+
void CRiBuffStruct::ToArray(SRiBuffStruct &array[])
{
    ArrayResize(array, GetTotal());
    int start = ToRealInd(0);
    if(start > m_head_index)
    {
        int lt = m_max_total-start;
        ArrayCopy(array, m_buffer, 0, start, lt);
        ArrayCopy(array, m_buffer, lt, 0, m_head_index+1);
    }
    else
    {
        ArrayCopy(array, m_buffer, 0, 0, m_head_index);
    }
}