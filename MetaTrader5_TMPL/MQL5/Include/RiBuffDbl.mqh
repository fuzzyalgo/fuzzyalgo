//+------------------------------------------------------------------+
//|                                                   RingBuffer.mqh |
//|                                 Copyright 2016, Vasiliy Sokolov. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, Vasiliy Sokolov."
#property link      "http://www.mql5.com"
//+------------------------------------------------------------------+
//| Double ring buffer                                               |
//+------------------------------------------------------------------+
class CRiBuffDbl
{
private:
   bool           m_full_buff;
   int            m_max_total;
   int            m_head_index;
   double         m_buffer[];
protected:
   virtual void   OnAddValue(double value);
   virtual void   OnRemoveValue(double value);
   virtual void   OnChangeValue(int index, double prev_value, double new_value);
   virtual void   OnChangeArray(void);
   virtual void   OnSetMaxTotal(int max_total);
   int            ToRealInd(int index);
public:
                  CRiBuffDbl(void);
   void           AddValue(double value);
   void           ChangeValue(int index, double new_value);
   double         GetValue(int index);
   int            GetTotal(void);
   int            GetMaxTotal(void);
   void           SetMaxTotal(int max_total);
   void           ToArray(double& array[]);
};
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CRiBuffDbl::CRiBuffDbl(void) :   m_full_buff(false),
                                 m_head_index(-1),
                                 m_max_total(0)
{
   SetMaxTotal(3);
}
//+------------------------------------------------------------------+
//| Called when a new value is received                              |
//+------------------------------------------------------------------+
void CRiBuffDbl::OnAddValue(double value)
{
}
//+------------------------------------------------------------------+
//| Called when an old value is removed                              |
//+------------------------------------------------------------------+
void CRiBuffDbl::OnRemoveValue(double value)
{
}
//+------------------------------------------------------------------+
//| Called when an old value is changed                              |
//+------------------------------------------------------------------+
void CRiBuffDbl::OnChangeValue(int index,double prev_value,double new_value)
{
}
//+------------------------------------------------------------------+
//| Called when changing the number of elements in the buffer        |
//+------------------------------------------------------------------+
void CRiBuffDbl::OnSetMaxTotal(int max_total)
{
}
//+------------------------------------------------------------------+
//| Called if the entire array should be counted                     |
//+------------------------------------------------------------------+
void CRiBuffDbl::OnChangeArray(void)
{
}
//+------------------------------------------------------------------+
//| Set the new size of the ring buffer                              |
//+------------------------------------------------------------------+
void CRiBuffDbl::SetMaxTotal(int max_total)
{
   if(ArraySize(m_buffer) == max_total)
      return;
   m_max_total = ArrayResize(m_buffer, max_total);
   OnSetMaxTotal(m_max_total);
}
//+------------------------------------------------------------------+
//| Get the actual ring buffer size                                  |
//+------------------------------------------------------------------+
int CRiBuffDbl::GetMaxTotal(void)
{
   return m_max_total;
}
//+------------------------------------------------------------------+
//| Get the index value                                              |
//+------------------------------------------------------------------+
double CRiBuffDbl::GetValue(int index)
{
    int idx = ToRealInd(index);
    if( (idx < m_max_total) && ( 0 <= idx) )
        return m_buffer[idx];
    else
        return m_buffer[0]; 

   //return m_buffer[ToRealInd(index)];
}
//+------------------------------------------------------------------+
//| Get the total number of elements                                 |
//+------------------------------------------------------------------+
int CRiBuffDbl::GetTotal(void)
{
   if(m_full_buff)
      return m_max_total;
   return m_head_index+1;
}
//+------------------------------------------------------------------+
//| Add a new value to the ring buffer                               |
//+------------------------------------------------------------------+
void CRiBuffDbl::AddValue(double value)
{
   if(++m_head_index == m_max_total)
   {
      m_head_index = 0;
      m_full_buff = true;
   }  
   double last_value = 0.0;
   if(m_full_buff)
      last_value = m_buffer[m_head_index];
   m_buffer[m_head_index] = value;
   OnAddValue(value);
   if(m_full_buff)
      OnRemoveValue(last_value);
   OnChangeArray();
}
//+------------------------------------------------------------------+
//| Replace the previously added value with the new one              |
//+------------------------------------------------------------------+
void CRiBuffDbl::ChangeValue(int index, double value)
{
   int r_index = ToRealInd(index);
   double prev_value = m_buffer[r_index];
   m_buffer[r_index] = value;
   OnChangeValue(index, prev_value, value);
   OnChangeArray();
}
//+------------------------------------------------------------------+
//| Convert the virtual index into a real one                        |
//+------------------------------------------------------------------+
int CRiBuffDbl::ToRealInd(int index)
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
void CRiBuffDbl::ToArray(double &array[])
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
      ArrayCopy(array, m_buffer, 0, 0, m_head_index);
}